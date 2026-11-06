package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.backup.BackupDumpJob;
import com.sgiu_group.sgiu.backup.BackupUploader;
import com.sgiu_group.sgiu.models.dtos.BackupEstadoDTO;
import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/backups")
@RequiredArgsConstructor
public class BackupController {

    private final BackupDumpJob backupDumpJob;
    private final BackupUploader backupUploader;
    private final ConfiguracionNegocioRepository configuracionRepository;

    /**
     * R-11: Endpoint de consulta del estado de salud del último respaldo.
     * Consumido por el Shell del Frontend para renderizar el banner de estado (H-SHELL-05).
     */
    @GetMapping("/estado")
    public ResponseEntity<BackupEstadoDTO> obtenerEstadoBackup() {
        Optional<File> ultimoOpt = backupDumpJob.obtenerUltimoRespaldoLocal();
        boolean b2Configurado = backupUploader.isConfigurado();

        if (ultimoOpt.isEmpty()) {
            return ResponseEntity.ok(BackupEstadoDTO.builder()
                    .estado("CRITICO")
                    .ultimoBackupTimestamp(null)
                    .horasDesdeUltimo(null)
                    .ultimoArchivo(null)
                    .almacenamientoRemoto(b2Configurado ? "CONFIGURADO" : "NO_CONFIGURADO")
                    .mensaje("Peligro: No se registran copias de seguridad válidas del sistema.")
                    .build());
        }

        File ultimoArchivo = ultimoOpt.get();
        LocalDateTime fechaUltimo = BackupDumpJob.extraerFechaDeArchivo(ultimoArchivo);
        LocalDateTime ahora = LocalDateTime.now();

        long horas = (fechaUltimo != null) ? Duration.between(fechaUltimo, ahora).toHours() : 0;
        if (horas < 0) {
            horas = 0; // Protege ante pequeñas discrepancias de reloj
        }

        String estado;
        String mensaje;
        if (horas <= 24) {
            estado = "AL_DIA";
            mensaje = "Respaldo al día (hace " + horas + " horas).";
        } else {
            estado = "DESACTUALIZADO";
            mensaje = "Atención: El último respaldo tiene más de 24 horas (" + horas + " h). Realice un respaldo manual.";
        }

        String almacenamientoRemoto = b2Configurado ? "CONFIGURADO" : "LOCAL_ONLY";

        return ResponseEntity.ok(BackupEstadoDTO.builder()
                .estado(estado)
                .ultimoBackupTimestamp(fechaUltimo != null ? fechaUltimo.toString() : null)
                .horasDesdeUltimo(horas)
                .ultimoArchivo(ultimoArchivo.getName())
                .almacenamientoRemoto(almacenamientoRemoto)
                .mensaje(mensaje)
                .build());
    }

    @PostMapping("/ejecutar")
    public ResponseEntity<Map<String, Object>> ejecutarBackup() {
        try {
            String ubicacion = backupDumpJob.ejecutarBackup();
            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("mensaje", "Backup generado y procesado exitosamente");
            response.put("ubicacion", ubicacion);
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error al ejecutar backup manual: {}", e.getMessage(), e);
            Map<String, Object> error = new HashMap<>();
            error.put("error", "No se pudo ejecutar el backup: " + e.getMessage());
            return ResponseEntity.internalServerError().body(error);
        }
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> listarBackups() {
        String codigoCliente = configuracionRepository.findFirstByOrderByIdAsc()
                .map(ConfiguracionNegocio::getCodigoCliente)
                .orElse("SGIU-DEFAULT");

        List<String> respaldos = backupUploader.listarBackups(codigoCliente);
        Map<String, Object> response = new HashMap<>();
        response.put("codigoCliente", codigoCliente);
        response.put("b2Configurado", backupUploader.isConfigurado());
        response.put("archivos", respaldos);
        response.put("total", respaldos.size());
        return ResponseEntity.ok(response);
    }
}
