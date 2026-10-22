package com.sgiu_group.sgiu.backup;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.File;
import java.io.FileInputStream;
import java.net.URI;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Uploader de copias de seguridad hacia Backblaze B2 (API compatible con AWS S3).
 * Cumple con ISO/IEC 27001 (Control 8.13), NIST SP 800-34 y regla 3-2-1.
 */
@Slf4j
@Component
public class BackupUploader {

    @Value("${b2.bucket:sgiu-sandra-pruebas}")
    private String bucketName;

    @Value("${b2.endpoint:https://s3.ca-east-006.backblazeb2.com}")
    private String endpoint;

    @Value("${b2.region:ca-east-006}")
    private String region;

    @Value("${b2.keyId:${AWS_ACCESS_KEY_ID:}}")
    private String keyId;

    @Value("${b2.applicationKey:${AWS_SECRET_ACCESS_KEY:}}")
    private String applicationKey;

    private S3Client s3Client;

    public void setS3Client(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    public boolean isConfigurado() {
        return (s3Client != null) || (keyId != null && !keyId.isBlank() && applicationKey != null && !applicationKey.isBlank());
    }

    public synchronized S3Client getOrCreateS3Client() {
        if (this.s3Client != null) {
            return this.s3Client;
        }
        if (!isConfigurado()) {
            throw new IllegalStateException("Credenciales de Backblaze B2 no configuradas.");
        }
        String regionName = (region != null && !region.isBlank()) ? region.trim() : "ca-east-006";
        AwsBasicCredentials credentials = AwsBasicCredentials.create(keyId.trim(), applicationKey.trim());
        this.s3Client = S3Client.builder()
                .endpointOverride(URI.create(endpoint.trim()))
                .region(Region.of(regionName))
                .credentialsProvider(StaticCredentialsProvider.create(credentials))
                .forcePathStyle(true)
                .build();
        return this.s3Client;
    }

    public String subirABucket(File dump, String codigoCliente) {
        if (dump == null || !dump.exists()) {
            throw new IllegalArgumentException("El archivo de backup no existe o es nulo.");
        }

        long tamanio = dump.length();
        if (tamanio < 15_360L) {
            throw new IllegalArgumentException("El archivo de backup es menor a 15 KB (" + tamanio + " bytes). Posible volcado incompleto o corrupto.");
        }

        String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
        String s3Key = String.format("dumps/%s/%s", tenant, dump.getName());
        String rutaRemota = String.format("s3://%s/%s", bucketName, s3Key);

        if (!isConfigurado()) {
            log.info("[BACKUP B2] Credenciales no configuradas. Respaldo conservado localmente en: {}", dump.getAbsolutePath());
            return rutaRemota + " (LOCAL_ONLY)";
        }

        try {
            String sha256Hex = calcularSha256(dump);
            log.info("[BACKUP B2] Subiendo {} ({} bytes, sha256={}) hacia {}", dump.getName(), tamanio, sha256Hex, rutaRemota);

            S3Client client = getOrCreateS3Client();

            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .metadata(Map.of("sha256", sha256Hex, "tenant", tenant))
                    .build();

            client.putObject(putRequest, RequestBody.fromFile(dump));
            log.info("[BACKUP B2] Archivo {} subido exitosamente a Backblaze B2.", dump.getName());

            // Si existe el archivo companion .sha256, también se sube al bucket
            File companionSha = new File(dump.getAbsolutePath() + ".sha256");
            if (companionSha.exists()) {
                String shaKey = s3Key + ".sha256";
                PutObjectRequest shaRequest = PutObjectRequest.builder()
                        .bucket(bucketName)
                        .key(shaKey)
                        .build();
                client.putObject(shaRequest, RequestBody.fromFile(companionSha));
                log.info("[BACKUP B2] Archivo de verificación {} subido exitosamente.", shaKey);
            }

            return rutaRemota;
        } catch (Exception e) {
            log.error("[BACKUP B2] Error al subir backup a B2: {}", e.getMessage(), e);
            throw new RuntimeException("Error al subir el volcado a Backblaze B2: " + e.getMessage(), e);
        }
    }

    /**
     * Rotación remota (30 diarios + 12 mensuales).
     * Conserva los últimos 30 backups diarios y 1 backup mensual para los últimos 12 meses.
     * Retorna la cantidad de backups remotos eliminados.
     */
    public int limpiarRemotos(String codigoCliente) {
        if (!isConfigurado()) {
            log.debug("[BACKUP B2 LIFECYCLE] B2 no configurado. Se omite rotación remota.");
            return 0;
        }

        try {
            S3Client client = getOrCreateS3Client();
            String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
            String prefix = String.format("dumps/%s/", tenant);

            ListObjectsV2Request listReq = ListObjectsV2Request.builder()
                    .bucket(bucketName)
                    .prefix(prefix)
                    .build();

            ListObjectsV2Response listRes = client.listObjectsV2(listReq);
            List<S3Object> objects = listRes.contents();
            if (objects == null || objects.isEmpty()) {
                return 0;
            }

            Pattern datePattern = Pattern.compile(".*_(\\d{4})(\\d{2})(\\d{2})_.*");
            LocalDate hoy = LocalDate.now();
            LocalDate limite30Dias = hoy.minusDays(30);
            LocalDate limite12Meses = hoy.minusMonths(12);

            Map<String, S3Object> mensualConservado = new HashMap<>();
            List<ObjectIdentifier> paraBorrar = new ArrayList<>();

            for (S3Object obj : objects) {
                String key = obj.key();
                if (key.endsWith(".sha256")) {
                    continue;
                }
                Matcher matcher = datePattern.matcher(key);
                if (matcher.matches()) {
                    int anio = Integer.parseInt(matcher.group(1));
                    int mes = Integer.parseInt(matcher.group(2));
                    int dia = Integer.parseInt(matcher.group(3));
                    LocalDate fechaBackup = LocalDate.of(anio, mes, dia);

                    if (fechaBackup.isAfter(limite30Dias)) {
                        // Conservar: dentro de los 30 diarios
                        continue;
                    }

                    if (fechaBackup.isAfter(limite12Meses)) {
                        // Período mensual: conservar solo 1 backup por mes
                        String claveMes = String.format("%04d-%02d", anio, mes);
                        if (!mensualConservado.containsKey(claveMes)) {
                            mensualConservado.put(claveMes, obj);
                            continue;
                        }
                    }

                    // Obsoleto: marcar para eliminación
                    paraBorrar.add(ObjectIdentifier.builder().key(key).build());
                    paraBorrar.add(ObjectIdentifier.builder().key(key + ".sha256").build());
                }
            }

            if (!paraBorrar.isEmpty()) {
                DeleteObjectsRequest delReq = DeleteObjectsRequest.builder()
                        .bucket(bucketName)
                        .delete(Delete.builder().objects(paraBorrar).build())
                        .build();
                client.deleteObjects(delReq);
                log.info("[BACKUP B2 LIFECYCLE] Se eliminaron {} objetos obsoletos en B2.", paraBorrar.size());
            }

            return paraBorrar.size();
        } catch (Exception e) {
            log.warn("[BACKUP B2 LIFECYCLE] Error durante la rotación remota: {}", e.getMessage());
            return 0;
        }
    }

    public List<String> listarBackups(String codigoCliente) {
        String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
        List<String> listado = new ArrayList<>();
        File carpetaLocal = new File("backups");
        if (carpetaLocal.exists() && carpetaLocal.isDirectory()) {
            File[] files = carpetaLocal.listFiles((dir, name) -> name.endsWith(".sql.gz.enc") || name.endsWith(".sql.gz"));
            if (files != null) {
                for (File f : files) {
                    listado.add(f.getName());
                }
            }
        }
        return listado;
    }

    private String calcularSha256(File archivo) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (FileInputStream fis = new FileInputStream(archivo)) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = fis.read(buffer)) != -1) {
                    md.update(buffer, 0, read);
                }
            }
            byte[] digest = md.digest();
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (Exception e) {
            return "sha256-error:" + e.getMessage();
        }
    }
}
