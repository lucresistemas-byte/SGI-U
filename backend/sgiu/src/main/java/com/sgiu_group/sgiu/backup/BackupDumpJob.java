package com.sgiu_group.sgiu.backup;

import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.GZIPOutputStream;

@Slf4j
@Component
@RequiredArgsConstructor
public class BackupDumpJob {

    private final BackupUploader backupUploader;
    private final ConfiguracionNegocioRepository configuracionRepository;
    private final EncryptionService encryptionService;

    @Value("${spring.datasource.username:sgiu_user}")
    private String dbUser;

    // Sin password por defecto: en el instalador lo inyecta Launcher
    // (application.yml tampoco tiene default; en dev viene del entorno).
    @Value("${spring.datasource.password:}")
    private String dbPassword;

    @Value("${spring.datasource.url:jdbc:mariadb://localhost:3307/sgiu_db}")
    private String dbUrl;

    @Value("${sgiu.backup.catchup.enabled:true}")
    private boolean catchupHabilitado;

    @Value("${sgiu.backup.retention.local-days:14}")
    private int retencionLocalDias;

    @Value("${sgiu.backup.retention.remote-days:30}")
    private int retencionRemotaDias;

    // Se ejecuta al iniciar la aplicación (Catch-up si la PC estuvo apagada en el cron nocturno)
    @org.springframework.context.event.EventListener(org.springframework.boot.context.event.ApplicationReadyEvent.class)
    public void verificarYEjecutarCatchupAlIniciar() {
        if (!catchupHabilitado) {
            log.debug("[BACKUP CATCH-UP] Verificación de catch-up al inicio deshabilitada por configuración.");
            return;
        }

        java.util.concurrent.CompletableFuture.runAsync(() -> {
            try {
                // Espera de gracia para que la app complete su arranque sin competencia de I/O
                Thread.sleep(5000);
                String prefijoHoy = "sgiu_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
                File dirBackups = carpetaBackups();
                boolean existeHoy = existeRespaldoDeHoy(dirBackups, prefijoHoy);

                if (!existeHoy) {
                    log.info("[BACKUP CATCH-UP] No se encontró respaldo nocturno de hoy ({}). Computadora posiblemente apagada. Ejecutando respaldo automático en segundo plano...", prefijoHoy);
                    ejecutarBackup();
                } else {
                    log.info("[BACKUP CATCH-UP] Respaldo del día ya presente ({}). No se requiere ejecución de contingencia.", prefijoHoy);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.warn("[BACKUP CATCH-UP] Error al ejecutar respaldo de contingencia al inicio: {}", e.getMessage());
            }
        });
    }

    /**
     * Existe un respaldo de hoy? Considera tanto el .sql.gz plano como el
     * .sql.gz.enc (flujo real con cifrado A8). Package-private para tests.
     */
    boolean existeRespaldoDeHoy(File dirBackups, String prefijoHoy) {
        if (!dirBackups.exists() || !dirBackups.isDirectory()) {
            return false;
        }
        File[] archivos = dirBackups.listFiles((dir, name) ->
                name.startsWith(prefijoHoy)
                        && (name.endsWith(".sql.gz") || name.endsWith(".sql.gz.enc")));
        return archivos != null && archivos.length > 0;
    }

    // Se ejecuta según cron (default: 03:30 AM todos los días)
    @Scheduled(cron = "${sgiu.backup.cron:0 30 3 * * *}")
    public void ejecutarBackupProgramado() {
        log.info("[BACKUP JOB] Iniciando proceso de respaldo programado hacia Backblaze B2...");
        try {
            ejecutarBackup();
        } catch (Exception e) {
            log.warn("[BACKUP JOB] Falló la ejecución programada de backup: {}", e.getMessage());
        }
    }

    public String ejecutarBackup() throws IOException, InterruptedException {
        String codigoCliente = configuracionRepository.findFirstByOrderByIdAsc()
                .map(ConfiguracionNegocio::getCodigoCliente)
                .filter(c -> !c.isBlank())
                .orElse("SGIU-DEFAULT");

        File dump = generarDumpComprimido(codigoCliente);

        // A8: Cifra el dump con AES-256-GCM antes de subirlo y persiste el
        // SHA-256 del .gz (se verifica al restaurar, después de descifrar).
        String shaGz = calcularSha256(dump);
        escribirChecksum(new File(dump.getParentFile(), dump.getName() + ".sha256"), shaGz);

        File dumpCifrado;
        try {
            dumpCifrado = encryptionService.cifrar(dump);
            dump.delete(); // elimina el .sql.gz sin cifrar una vez que el .enc está listo
        } catch (Exception e) {
            log.error("[BACKUP A8] Error al cifrar el dump: {}", e.getMessage(), e);
            throw new IOException("Error al cifrar el backup: " + e.getMessage(), e);
        }

        // SHA-256 del .enc: detecta corrupción de red ANTES de descargarlo entero.
        String shaEnc = calcularSha256(dumpCifrado);
        escribirChecksum(new File(dumpCifrado.getParentFile(), dumpCifrado.getName() + ".sha256"), shaEnc);

        String ubicacion = backupUploader.subirABucket(dumpCifrado, codigoCliente);
        log.info("[BACKUP JOB] Backup cifrado y almacenado exitosamente: {}", ubicacion);

        // Rotaciones: la local nunca falla el backup del día; la remota
        // tampoco (BackupUploader ya loguea y devuelve 0 en error).
        rotarBackupsLocales(retencionLocalDias);
        backupUploader.limpiarRemotosMasAntiguos(codigoCliente, retencionRemotaDias);

        return ubicacion;
    }

    /** A6: Propiedad opcional para forzar la ruta de mariadb-dump.exe (útil en tests). */
    @Value("${sgiu.backup.dump.path:}")
    private String dumpPathConfig;

    public File generarDumpComprimido(String codigoCliente) throws IOException, InterruptedException {
        File dirBackups = carpetaBackups();
        if (!dirBackups.exists()) {
            dirBackups.mkdirs();
        }

        String timestamp = LocalDateTime.now()
                .format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        File archivoSalida = new File(dirBackups, "sgiu_" + timestamp + ".sql.gz");

        // A6: resolución determinística de mariadb-dump.exe
        String dumpExe = resolverRutaDump();

        // R-02 (MUST): La contraseña de la base NUNCA debe figurar en la línea de comandos
        // (argumentos visibles por Win32_Process o Administrador de Tareas).
        // Se genera un archivo de opciones temporal protegido (--defaults-extra-file) con permisos restrictivos.
        File tempConfigFile = File.createTempFile("sgiu_dump_", ".cnf");
        try {
            String configContent = "[client]\n"
                    + "user=" + dbUser + "\n"
                    + "password=" + (dbPassword != null ? dbPassword : "") + "\n"
                    + "port=" + extraerPuerto() + "\n";
            Files.writeString(tempConfigFile.toPath(), configContent, StandardCharsets.UTF_8);

            List<String> comando = new ArrayList<>(List.of(
                    dumpExe,
                    "--defaults-extra-file=" + tempConfigFile.getAbsolutePath(),
                    "--databases", extraerBaseDeDatos(),
                    "--routines",
                    "--triggers",
                    "--events",
                    "--single-transaction"
            ));

            ProcessBuilder pb = new ProcessBuilder(comando);
            // Inyectamos también MYSQL_PWD en el environment del proceso como capa de compatibilidad
            if (dbPassword != null && !dbPassword.isBlank()) {
                pb.environment().put("MYSQL_PWD", dbPassword);
            }
            pb.redirectErrorStream(false);
            Process proceso = pb.start();

            // Lee stderr en hilo separado para que no se bloquee el buffer
            final StringBuilder stderr = new StringBuilder();
            Thread stderrReader = new Thread(() -> {
                try (java.io.BufferedReader reader = new java.io.BufferedReader(
                        new java.io.InputStreamReader(proceso.getErrorStream(), StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        stderr.append(line).append('\n');
                    }
                } catch (IOException ignored) { }
            });
            stderrReader.setDaemon(true);
            stderrReader.start();

            try (InputStream in = proceso.getInputStream();
                 FileOutputStream fos = new FileOutputStream(archivoSalida);
                 GZIPOutputStream gzos = new GZIPOutputStream(fos)) {

                byte[] buffer = new byte[8192];
                int read;
                while ((read = in.read(buffer)) != -1) {
                    gzos.write(buffer, 0, read);
                }
            }

            int exitCode = proceso.waitFor();
            stderrReader.join(3000);

            if (exitCode != 0) {
                archivoSalida.delete();
                throw new IOException("[BACKUP DUMP] mariadb-dump terminó con exitCode=" + exitCode
                        + ". Stderr: " + stderr);
            }
        } finally {
            // R-02: Garantiza borrado inmediato del archivo de configuración temporal
            if (tempConfigFile.exists()) {
                tempConfigFile.delete();
            }
        }

        long tamanio = archivoSalida.length();
        if (tamanio < 15_360L) { // < 15 KB → volcado vacío o roto
            archivoSalida.delete();
            throw new IOException("[BACKUP DUMP] Volcado demasiado pequeño (" + tamanio
                    + " bytes). El dump puede estar vacío o corrompido.");
        }

        // A6: Verificación de cabecera SQL (descomprimiendo solo los primeros bytes)
        try (java.util.zip.GZIPInputStream gzis = new java.util.zip.GZIPInputStream(
                new java.io.FileInputStream(archivoSalida))) {
            byte[] head = gzis.readNBytes(20);
            String header = new String(head, StandardCharsets.UTF_8);
            if (!header.startsWith("-- MariaDB dump") && !header.startsWith("-- MySQL dump")) {
                archivoSalida.delete();
                throw new IOException("[BACKUP DUMP] El archivo no contiene una cabecera SQL válida.");
            }
        }

        String sha256 = calcularSha256(archivoSalida);
        log.info("[BACKUP DUMP] Dump OK. Tamaño={} bytes, SHA-256={}, archivo={}",
                tamanio, sha256, archivoSalida.getName());

        return archivoSalida;
    }

    /**
     * A6/retención: borra en {@code backups/} los respaldos con más de
     * {@code dias} días (.sql.gz, .enc y .sha256 asociados). Nunca lanza:
     * la retención no debe abortar el respaldo del día.
     */
    public int rotarBackupsLocales(int dias) {
        if (dias <= 0) {
            return 0;
        }
        File dirBackups = carpetaBackups();
        if (!dirBackups.exists() || !dirBackups.isDirectory()) {
            return 0;
        }
        long corte = System.currentTimeMillis() - dias * 24L * 3600_000L;
        int borrados = 0;
        File[] archivos = dirBackups.listFiles((dir, name) ->
                name.endsWith(".sql.gz") || name.endsWith(".sql.gz.enc") || name.endsWith(".sha256"));
        if (archivos == null) {
            return 0;
        }
        for (File f : archivos) {
            if (f.lastModified() < corte) {
                if (f.delete()) {
                    borrados++;
                    log.info("[BACKUP ROTACIÓN] Eliminado local {} (más antiguo que {} días)", f.getName(), dias);
                }
            }
        }
        return borrados;
    }

    /**
     * A6: resuelve la ruta de mariadb-dump.exe: primero usa la propiedad sgiu.backup.dump.path,
     * luego busca junto al instalador (content/bin/), y por último el PATH del sistema.
     */
    private String resolverRutaDump() throws IOException {
        if (dumpPathConfig != null && !dumpPathConfig.isBlank()) {
            File f = new File(dumpPathConfig);
            if (f.exists()) return f.getAbsolutePath();
        }
        // Busca en content/bin/ (ruta del instalador)
        String javaHome = System.getProperty("java.home");
        if (javaHome != null) {
            File installer = new File(javaHome).getParentFile();
            File candidate = new File(installer, "content" + File.separator + "bin" + File.separator + "mariadb-dump.exe");
            if (candidate.exists()) return candidate.getAbsolutePath();
        }
        // Última opción: PATH del sistema (desarrollo con Docker)
        return "mariadb-dump";
    }

    /** Carpeta de respaldos locales. */
    public File carpetaBackups() {
        return new File("backups");
    }

    /**
     * Obtiene el último respaldo local existente (.sql.gz o .sql.gz.enc).
     * Como los nombres siguen la convención sgiu_yyyyMMdd_HHmmss.*, el orden
     * lexicográfico coincide exactamente con el orden cronológico.
     */
    public Optional<File> obtenerUltimoRespaldoLocal() {
        File dir = carpetaBackups();
        if (!dir.exists() || !dir.isDirectory()) {
            return Optional.empty();
        }
        File[] archivos = dir.listFiles((d, name) ->
                (name.endsWith(".sql.gz.enc") || name.endsWith(".sql.gz"))
                        && !name.endsWith(".sha256")
                        && name.startsWith("sgiu_"));
        if (archivos == null || archivos.length == 0) {
            return Optional.empty();
        }
        return Arrays.stream(archivos)
                .max(Comparator.comparing(File::getName));
    }

    /**
     * Extrae la marca temporal del nombre del archivo (formato: sgiu_yyyyMMdd_HHmmss...).
     * Si el nombre no coincide con el patrón esperado, recurre a lastModified() como fallback.
     */
    public static LocalDateTime extraerFechaDeArchivo(File archivo) {
        if (archivo == null) return null;
        String name = archivo.getName();
        Matcher matcher = Pattern.compile("sgiu_(\\d{4})(\\d{2})(\\d{2})_(\\d{2})(\\d{2})(\\d{2})").matcher(name);
        if (matcher.find()) {
            int anio = Integer.parseInt(matcher.group(1));
            int mes = Integer.parseInt(matcher.group(2));
            int dia = Integer.parseInt(matcher.group(3));
            int hora = Integer.parseInt(matcher.group(4));
            int min = Integer.parseInt(matcher.group(5));
            int seg = Integer.parseInt(matcher.group(6));
            return LocalDateTime.of(anio, mes, dia, hora, min, seg);
        }
        return java.time.Instant.ofEpochMilli(archivo.lastModified())
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalDateTime();
    }

    /** Puerto del dump tomado de spring.datasource.url (3307 en Windows, 3306 en Docker). */
    String extraerPuerto() {
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile(":(\\d+)/").matcher(dbUrl == null ? "" : dbUrl);
        return m.find() ? m.group(1) : "3307";
    }

    /** Base de datos tomada de spring.datasource.url (default sgiu_db). */
    String extraerBaseDeDatos() {
        if (dbUrl == null || dbUrl.isBlank()) {
            return "sgiu_db";
        }
        int barra = dbUrl.lastIndexOf('/');
        if (barra < 0 || barra == dbUrl.length() - 1) {
            return "sgiu_db";
        }
        String db = dbUrl.substring(barra + 1);
        int interrogacion = db.indexOf('?');
        return interrogacion >= 0 ? db.substring(0, interrogacion) : db;
    }

    /** Escribe el checksum en formato compatible con `sha256sum -c`. */
    void escribirChecksum(File destino, String sha256Hex) throws IOException {
        try (Writer w = new OutputStreamWriter(new FileOutputStream(destino), StandardCharsets.UTF_8)) {
            w.write(sha256Hex + "  " + quitarExtChecksum(destino.getName()) + System.lineSeparator());
        }
        log.info("[BACKUP DUMP] Checksum escrito: {}", destino.getName());
    }

    private static String quitarExtChecksum(String nombre) {
        return nombre.endsWith(".sha256") ? nombre.substring(0, nombre.length() - ".sha256".length()) : nombre;
    }

    /** A6: Calcula el SHA-256 de un archivo y lo devuelve en hex. */
    public String calcularSha256(File archivo) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
            try (java.io.FileInputStream fis = new java.io.FileInputStream(archivo)) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = fis.read(buffer)) != -1) md.update(buffer, 0, read);
            }
            byte[] digest = md.digest();
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) hex.append(String.format("%02x", b));
            return hex.toString();
        } catch (Exception e) {
            return "sha256-error:" + e.getMessage();
        }
    }
}
