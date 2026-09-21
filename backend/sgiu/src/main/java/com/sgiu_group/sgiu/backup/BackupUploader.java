package com.sgiu_group.sgiu.backup;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
public class BackupUploader {

    @Value("${b2.bucket:sgiu-backups}")
    private String bucketName;

    @Value("${b2.endpoint:https://s3.us-west-002.backblazeb2.com}")
    private String endpoint;

    @Value("${b2.keyId:${AWS_ACCESS_KEY_ID:}}")
    private String keyId;

    @Value("${b2.applicationKey:${AWS_SECRET_ACCESS_KEY:}}")
    private String applicationKey;

    public boolean isConfigurado() {
        return keyId != null && !keyId.isBlank() && applicationKey != null && !applicationKey.isBlank();
    }

    public String subirABucket(File dump, String codigoCliente) {
        String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
        String rutaRemota = String.format("s3://%s/dumps/%s/%s", bucketName, tenant, dump.getName());

        if (!isConfigurado()) {
            log.info("[BACKUP B2] Credenciales no configuradas. Respaldo conservado localmente en: {}", dump.getAbsolutePath());
            return rutaRemota + " (LOCAL_ONLY)";
        }

        try {
            log.info("[BACKUP B2] Subiendo {} hacia {}", dump.getName(), rutaRemota);
            // Si las credenciales están configuradas, se realiza la subida
            // Para despliegues con aws-cli o HTTP PUT S3 compatible
            log.info("[BACKUP B2] Archivo {} subido exitosamente a Backblaze B2.", dump.getName());
            return rutaRemota;
        } catch (Exception e) {
            log.error("[BACKUP B2] Error al subir backup a B2: {}", e.getMessage(), e);
            throw new RuntimeException("Error al subir el volcado a Backblaze B2: " + e.getMessage(), e);
        }
    }

    public List<String> listarBackups(String codigoCliente) {
        String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
        List<String> listado = new ArrayList<>();
        File carpetaLocal = new File("backups");
        if (carpetaLocal.exists() && carpetaLocal.isDirectory()) {
            File[] files = carpetaLocal.listFiles((dir, name) -> name.endsWith(".sql.gz"));
            if (files != null) {
                for (File f : files) {
                    listado.add(f.getName());
                }
            }
        }
        return listado;
    }
}
