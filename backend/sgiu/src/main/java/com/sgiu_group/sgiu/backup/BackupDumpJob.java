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
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
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

    @Value("${spring.datasource.password:sgiu_1234}")
    private String dbPassword;

    @Value("${sgiu.backup.catchup.enabled:true}")
    private boolean catchupHabilitado;

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
                File dirBackups = new File("backups");
                boolean existeHoy = false;
                if (dirBackups.exists() && dirBackups.isDirectory()) {
                    File[] archivos = dirBackups.listFiles((dir, name) -> name.startsWith(prefijoHoy) && name.endsWith(".sql.gz"));
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

        // A8: Cifra el dump con AES-256-GCM antes de subirlo
        File dumpCifrado;
        try {
            dumpCifrado = encryptionService.cifrar(dump);
            dump.delete(); // elimina el .sql.gz sin cifrar una vez que el .enc está listo
        } catch (Exception e) {
            log.error("[BACKUP A8] Error al cifrar el dump: {}", e.getMessage(), e);
            throw new IOException("Error al cifrar el backup: " + e.getMessage(), e);
        }

        String ubicacion = backupUploader.subirABucket(dumpCifrado, codigoCliente);
        log.info("[BACKUP JOB] Backup cifrado y almacenado exitosamente: {}", ubicacion);
        return ubicacion;
    }

    /** A6: Propiedad opcional para forzar la ruta de mariadb-dump.exe (útil en tests). */
    @Value("${sgiu.backup.dump.path:}")
    private String dumpPathConfig;

    public File generarDumpComprimido(String codigoCliente) throws IOException, InterruptedException {
        File dirBackups = new File("backups");
        if (!dirBackups.exists()) {
            dirBackups.mkdirs();
        }

        String timestamp = LocalDateTime.now()
                .format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        // A8: extensión .sql.gz.enc cuando el cifrado esté habilitado; por ahora .sql.gz
        File archivoSalida = new File(dirBackups, "sgiu_" + timestamp + ".sql.gz");

        // A6: resolución determinística de mariadb-dump.exe
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
        pb.redirectErrorStream(false); // stderr separado para loguear errores del proceso
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

        // A6: Validación estricta — no se emite éxito si algo falla
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

        // A6: Checksum SHA-256 (se loguea para trazabilidad)
        String sha256 = calcularSha256(archivoSalida);
        log.info("[BACKUP DUMP] Dump OK. Tamaño={} bytes, SHA-256={}, archivo={}",
                tamanio, sha256, archivoSalida.getName());

        return archivoSalida;
    }

    /**
     * A6: Resuelve la ruta de mariadb-dump.exe: primero usa la propiedad sgiu.backup.dump.path,
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

    /** A6: Calcula el SHA-256 de un archivo y lo devuelve en hex. */
    private String calcularSha256(File archivo) {
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
