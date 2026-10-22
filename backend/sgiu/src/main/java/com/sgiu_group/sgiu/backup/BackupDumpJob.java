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
import java.util.List;
import java.util.zip.GZIPOutputStream;

/**
 * Tarea periódica y bajo demanda para generación de backups cifrados y su rotación.
 * Cumple con ISO 27001 (8.13), NIST SP 800-34 (RPO < 24h) y NIST SP 800-38D (AES-GCM).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BackupDumpJob {

    private final BackupUploader backupUploader;
    private final ConfiguracionNegocioRepository configuracionRepository;
    private final EncryptionService encryptionService;

    @Value("${spring.datasource.username:sgiu_user}")
    private String dbUser;

    @Value("${spring.datasource.password:sgiu_1234}")
    private String dbPassword;

    @Value("${sgiu.backup.catchup.enabled:true}")
    private boolean catchupHabilitado;

    @Value("${sgiu.backup.retencion-dias:14}")
    private int diasRetencionLocal;

    /** Helper común de nomenclatura de backups. */
    public static String generarPrefijoDia(LocalDateTime fecha) {
        return "sgiu_" + fecha.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
    }

    public static String generarTimestamp(LocalDateTime fecha) {
        return fecha.format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
    }

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
                String prefijoHoy = generarPrefijoDia(LocalDateTime.now());
                File dirBackups = new File("backups");
                boolean existeHoy = false;
                if (dirBackups.exists() && dirBackups.isDirectory()) {
                    // Detección corregida: busca tanto .sql.gz.enc como .sql.gz
                    File[] archivos = dirBackups.listFiles((dir, name) ->
                            name.startsWith(prefijoHoy) && (name.endsWith(".sql.gz.enc") || name.endsWith(".sql.gz")));
                    existeHoy = (archivos != null && archivos.length > 0);
                }

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

        // Cifra el dump con AES-256-GCM antes de subirlo
        File dumpCifrado;
        try {
            dumpCifrado = encryptionService.cifrar(dump);
            dump.delete(); // elimina el .sql.gz sin cifrar una vez que el .enc está listo
        } catch (Exception e) {
            log.error("[BACKUP] Error al cifrar el dump: {}", e.getMessage(), e);
            throw new IOException("Error al cifrar el backup: " + e.getMessage(), e);
        }

        // Genera y guarda archivo .sha256 del dump cifrado
        String sha256Cifrado = calcularSha256(dumpCifrado);
        File archivoSha = new File(dumpCifrado.getAbsolutePath() + ".sha256");
        try {
            Files.writeString(archivoSha.toPath(), sha256Cifrado + "  " + dumpCifrado.getName() + System.lineSeparator(), StandardCharsets.UTF_8);
            log.info("[BACKUP SHA256] Archivo de verificación generado: {}", archivoSha.getName());
        } catch (IOException e) {
            log.warn("[BACKUP SHA256] No se pudo escribir archivo .sha256: {}", e.getMessage());
        }

        // Subida al almacenamiento en la nube Backblaze B2
        String ubicacion = backupUploader.subirABucket(dumpCifrado, codigoCliente);
        log.info("[BACKUP JOB] Backup cifrado y almacenado exitosamente: {}", ubicacion);

        // Rotación remota (30 diarios + 12 mensuales)
        try {
            backupUploader.limpiarRemotos(codigoCliente);
        } catch (Exception e) {
            log.warn("[BACKUP ROTACION REMOTA] Advertencia en ciclo de vida B2: {}", e.getMessage());
        }

        // Rotación local: borrar archivos con más de 14 días conservando el actual
        File dirBackups = new File("backups");
        rotarBackupsLocales(dirBackups, dumpCifrado, diasRetencionLocal);

        return ubicacion;
    }

    /**
     * Elimina backups locales con antigüedad mayor a 'diasRetencion' días.
     * Garantiza que el archivo actual recién generado nunca sea eliminado.
     */
    public int rotarBackupsLocales(File dirBackups, File dumpActual, int diasRetencion) {
        if (dirBackups == null || !dirBackups.exists() || !dirBackups.isDirectory()) {
            return 0;
        }
        long limiteMtime = System.currentTimeMillis() - (diasRetencion * 24L * 60L * 60L * 1000L);
        File[] candidatos = dirBackups.listFiles((dir, name) ->
                name.endsWith(".sql.gz.enc") || name.endsWith(".sha256") || name.endsWith(".sql.gz"));

        int borrados = 0;
        if (candidatos != null) {
            for (File f : candidatos) {
                // Protección: nunca eliminar el backup actual ni su .sha256
                if (dumpActual != null && (f.getAbsolutePath().equals(dumpActual.getAbsolutePath()) ||
                        f.getAbsolutePath().equals(dumpActual.getAbsolutePath() + ".sha256"))) {
                    continue;
                }
                if (f.lastModified() < limiteMtime) {
                    log.info("[BACKUP ROTACION LOCAL] Purgando respaldo local antiguo (> {} días): {}", diasRetencion, f.getName());
                    if (f.delete()) {
                        borrados++;
                    }
                }
            }
        }
        return borrados;
    }

    /** Propiedad opcional para forzar la ruta de mariadb-dump.exe (útil en tests). */
    @Value("${sgiu.backup.dump.path:}")
    private String dumpPathConfig;

    public File generarDumpComprimido(String codigoCliente) throws IOException, InterruptedException {
        File dirBackups = new File("backups");
        if (!dirBackups.exists()) {
            dirBackups.mkdirs();
        }

        String timestamp = generarTimestamp(LocalDateTime.now());
        File archivoSalida = new File(dirBackups, "sgiu_" + timestamp + ".sql.gz");

        // Resolución determinística de mariadb-dump.exe
        String dumpExe = resolverRutaDump();

        List<String> comando = new ArrayList<>(List.of(
                dumpExe,
                "--databases", "sgiu_db",
                "--routines",
                "--triggers",
                "--single-transaction",
                "-u" + dbUser,
                "-p" + dbPassword,
                "-P3307"
        ));

        ProcessBuilder pb = new ProcessBuilder(comando);
        pb.redirectErrorStream(false);
        Process proceso = pb.start();

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

        long tamanio = archivoSalida.length();
        if (tamanio < 15_360L) { // < 15 KB → volcado vacío o roto
            archivoSalida.delete();
            throw new IOException("[BACKUP DUMP] Volcado demasiado pequeño (" + tamanio
                    + " bytes). El dump puede estar vacío o corrompido.");
        }

        // Verificación de cabecera SQL
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

    private String resolverRutaDump() throws IOException {
        if (dumpPathConfig != null && !dumpPathConfig.isBlank()) {
            File f = new File(dumpPathConfig);
            if (f.exists()) return f.getAbsolutePath();
        }
        String javaHome = System.getProperty("java.home");
        if (javaHome != null) {
            File installer = new File(javaHome).getParentFile();
            File candidate = new File(installer, "content" + File.separator + "bin" + File.separator + "mariadb-dump.exe");
            if (candidate.exists()) return candidate.getAbsolutePath();
        }
        return "mariadb-dump";
    }

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
