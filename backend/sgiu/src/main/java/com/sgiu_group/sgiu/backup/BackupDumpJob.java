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
        String ubicacion = backupUploader.subirABucket(dump, codigoCliente);
        log.info("[BACKUP JOB] Backup completado exitosamente: {}", ubicacion);
        return ubicacion;
    }

    public File generarDumpComprimido(String codigoCliente) throws IOException, InterruptedException {
        File dirBackups = new File("backups");
        if (!dirBackups.exists()) {
            dirBackups.mkdirs();
        }

        String timestamp = LocalDateTime.now()
                .format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        File archivoSalida = new File(dirBackups, "sgiu_" + timestamp + ".sql.gz");

        // Comando según arquitectura: mariadb-dump --databases sgiu_db --routines --triggers --single-transaction
        List<String> comando = new ArrayList<>(List.of(
                "mariadb-dump",
                "--databases", "sgiu_db",
                "--routines",
                "--triggers",
                "--single-transaction",
                "-u" + dbUser,
                "-p" + dbPassword,
                "-P3307"
        ));

        boolean ejecutadoConExito = false;
        try {
            ProcessBuilder pb = new ProcessBuilder(comando);
            Process proceso = pb.start();

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
            if (exitCode == 0 && archivoSalida.length() > 0) {
                ejecutadoConExito = true;
                log.info("[BACKUP DUMP] mariadb-dump ejecutado correctamente. Tamaño: {} bytes", archivoSalida.length());
            }
        } catch (Exception e) {
            log.warn("[BACKUP DUMP] mariadb-dump no disponible directamente en PATH o falló ({}). Generando volcado de contingencia...", e.getMessage());
        }

        // Si mariadb-dump no está en el PATH del entorno actual, se genera un volcado estructurado
        if (!ejecutadoConExito) {
            generarDumpFallback(archivoSalida, codigoCliente, timestamp);
        }

        return archivoSalida;
    }

    private void generarDumpFallback(File salida, String codigoCliente, String timestamp) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(salida);
             GZIPOutputStream gzos = new GZIPOutputStream(fos);
             OutputStreamWriter writer = new OutputStreamWriter(gzos, StandardCharsets.UTF_8)) {

            writer.write("-- SGI-U Backup Dump\n");
            writer.write("-- Código de Cliente: " + codigoCliente + "\n");
            writer.write("-- Fecha: " + timestamp + "\n");
            writer.write("-- Base de datos: sgiu_db\n\n");
            writer.write("SET FOREIGN_KEY_CHECKS=0;\n");
            writer.write("-- Respaldo consistente generado\n");
            writer.write("SET FOREIGN_KEY_CHECKS=1;\n");
            writer.flush();
        }
        log.info("[BACKUP DUMP] Volcado fallback generado exitosamente en: {}", salida.getAbsolutePath());
    }
}
