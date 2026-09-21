package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.backup.BackupDumpJob;
import com.sgiu_group.sgiu.backup.BackupUploader;
import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/backups")
@RequiredArgsConstructor
public class BackupController {

    private final BackupDumpJob backupDumpJob;
    private final BackupUploader backupUploader;
    private final ConfiguracionNegocioRepository configuracionRepository;

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
            error.put("status", "error");
            error.put("mensaje", "Error al ejecutar backup: " + e.getMessage());
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
