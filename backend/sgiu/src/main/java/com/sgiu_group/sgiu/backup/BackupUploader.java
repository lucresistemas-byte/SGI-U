package com.sgiu_group.sgiu.backup;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.File;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

/**
 * A6: subida REAL de backups a Backblaze B2 usando la API nativa de B2
 * (authorize → list_buckets → get_upload_url → upload_file), sin
 * dependencias externas: solo java.net.http del JDK.
 * <p>
 * Credenciales: applicationKeyID en {@code AWS_ACCESS_KEY_ID} y
 * applicationKey en {@code AWS_SECRET_ACCESS_KEY} (variables de entorno,
 * nunca en el repo). Sin credenciales el backup queda solo local
 * ({@code LOCAL_ONLY}); con credenciales, si la subida falla se lanza
 * excepción: nunca se loguea un éxito ficticio.
 */
@Slf4j
@Component
public class BackupUploader {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Value("${b2.bucket:sgiu-backups}")
    private String bucketName;

    @Value("${b2.apiUrl:https://api.backblazeb2.com}")
    private String apiUrlBase;

    @Value("${b2.keyId:${AWS_ACCESS_KEY_ID:}}")
    private String keyId;

    @Value("${b2.applicationKey:${AWS_SECRET_ACCESS_KEY:}}")
    private String applicationKey;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(30))
            .build();

    // Sesión B2 cacheada (el token de authorize dura la sesión de la API).
    private volatile String apiUrl;
    private volatile String accountToken;
    private volatile String bucketId;

    public boolean isConfigurado() {
        return keyId != null && !keyId.isBlank() && applicationKey != null && !applicationKey.isBlank();
    }

    /**
     * Sube el archivo cifrado y su checksum a dumps/<codigoCliente>/.
     * Lanza excepción si la subida falla (A6: sin éxito ficticio).
     */
    public String subirABucket(File dump, String codigoCliente) {
        String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
        String rutaRemota = String.format("b2://%s/dumps/%s/%s", bucketName, tenant, dump.getName());

        if (!isConfigurado()) {
            log.info("[BACKUP B2] Credenciales no configuradas. Respaldo conservado localmente en: {}", dump.getAbsolutePath());
            return rutaRemota + " (LOCAL_ONLY)";
        }

        try {
            log.info("[BACKUP B2] Subiendo {} hacia {}", dump.getName(), rutaRemota);
            subirArchivo(dump, "dumps/" + tenant + "/" + dump.getName(), "application/octet-stream");

            // El checksum acompaña al archivo: permite verificar integridad
            // antes de restaurar (y antes de descargar el archivo grande).
            File shaFile = new File(dump.getParentFile(), dump.getName() + ".sha256");
            if (shaFile.exists()) {
                subirArchivo(shaFile, "dumps/" + tenant + "/" + shaFile.getName(), "text/plain");
            }
            // También el hash del .sql.gz original: sirve para verificar el
            // archivo resultante DESPUÉS de descifrar el .enc.
            File shaGz = new File(dump.getParentFile(), quitarExtensionEnc(dump.getName()) + ".sha256");
            if (shaGz.exists()) {
                subirArchivo(shaGz, "dumps/" + tenant + "/" + shaGz.getName(), "text/plain");
            }

            log.info("[BACKUP B2] Archivo {} subido exitosamente a Backblaze B2.", dump.getName());
            return rutaRemota;
        } catch (Exception e) {
            log.error("[BACKUP B2] Error al subir backup a B2: {}", e.getMessage(), e);
            throw new RuntimeException("Error al subir el volcado a Backblaze B2: " + e.getMessage(), e);
        }
    }

    /**
     * A6/rotación remota: borra del bucket los archivos del prefijo
     * dumps/<tenant>/ con más de {@code dias} días.
     */
    public int limpiarRemotosMasAntiguos(String codigoCliente, int dias) {
        if (!isConfigurado()) {
            return 0;
        }
        String tenant = (codigoCliente != null && !codigoCliente.isBlank()) ? codigoCliente : "DEFAULT";
        String prefijo = "dumps/" + tenant + "/";
        try {
            autenticar();
            JsonNode listado = postJson(apiUrl + "/b2api/v2/b2_list_file_names",
                    MAPPER.createObjectNode()
                            .put("bucketId", bucketId)
                            .put("prefix", prefijo)
                            .put("maxFileCount", 1000));
            int borrados = 0;
            long corte = System.currentTimeMillis() - dias * 24L * 3600_000L;
            for (JsonNode archivo : listado.path("files")) {
                long ts = archivo.path("uploadTimestamp").asLong(0);
                if (ts > 0 && ts < corte) {
                    postJson(apiUrl + "/b2api/v2/b2_delete_file_version",
                            MAPPER.createObjectNode()
                                    .put("fileName", archivo.path("fileName").asText())
                                    .put("fileId", archivo.path("fileId").asText()));
                    borrados++;
                    log.info("[BACKUP B2] Rotación remota: eliminado {} ({} días)", archivo.path("fileName").asText(), dias);
                }
            }
            return borrados;
        } catch (Exception e) {
            // La rotación remota no debe tirar abajo el backup del día.
            log.warn("[BACKUP B2] Falló la rotación remota ({}): {}", dias, e.getMessage());
            return 0;
        }
    }

    public List<String> listarBackups(String codigoCliente) {
        List<String> listado = new ArrayList<>();
        File carpetaLocal = carpetaBackups();
        if (carpetaLocal.exists() && carpetaLocal.isDirectory()) {
            // El flujo real deja .sql.gz.enc (cifrado) y sus .sha256; el
            // .sql.gz plano solo existe si el cifrado está deshabilitado.
            File[] files = carpetaLocal.listFiles((dir, name) ->
                    name.endsWith(".sql.gz") || name.endsWith(".sql.gz.enc"));
            if (files != null) {
                for (File f : files) {
                    listado.add(f.getName());
                }
            }
        }
        return listado;
    }

    /** Carpeta de respaldos locales (package-private para tests). */
    File carpetaBackups() {
        return new File("backups");
    }

    // ------------------------------------------------------------------
    //  API nativa de Backblaze B2
    // ------------------------------------------------------------------

    private void subirArchivo(File archivo, String nombreRemoto, String contentType) throws Exception {
        autenticar();
        JsonNode upload = postJson(apiUrl + "/b2api/v2/b2_get_upload_url",
                MAPPER.createObjectNode().put("bucketId", bucketId));
        String uploadUrl = upload.path("uploadUrl").asText();
        String uploadToken = upload.path("authorizationToken").asText();

        String sha1Hex = sha1Hex(archivo);
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(uploadUrl))
                .timeout(Duration.ofMinutes(10))
                .header("Authorization", uploadToken)
                .header("X-Bz-File-Name", java.net.URLEncoder.encode(nombreRemoto, StandardCharsets.UTF_8)
                        .replace("+", "%20"))
                .header("X-Bz-Content-Sha1", sha1Hex)
                .header("Content-Type", contentType)
                .POST(HttpRequest.BodyPublishers.ofFile(archivo.toPath()))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOExceptionB2("b2_upload_file devolvió HTTP " + response.statusCode()
                    + ": " + truncar(response.body()));
        }
        log.info("[BACKUP B2] {} subido ({} bytes, sha1={})", nombreRemoto, archivo.length(), sha1Hex);
    }

    private synchronized void autenticar() throws Exception {
        if (apiUrl != null && accountToken != null && bucketId != null) {
            return;
        }
        String credenciales = Base64.getEncoder()
                .encodeToString((keyId + ":" + applicationKey).getBytes(StandardCharsets.UTF_8));
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(apiUrlBase + "/b2api/v2/b2_authorize_account"))
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", "Basic " + credenciales)
                .GET()
                .build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new IOExceptionB2("b2_authorize_account devolvió HTTP " + response.statusCode()
                    + ": " + truncar(response.body()));
        }
        JsonNode json = MAPPER.readTree(response.body());
        this.apiUrl = json.path("apiUrl").asText();
        this.accountToken = json.path("authorizationToken").asText();

        JsonNode buckets = postJson(apiUrl + "/b2api/v2/b2_list_buckets",
                MAPPER.createObjectNode().put("accountId", json.path("accountId").asText()));
        for (JsonNode b : buckets.path("buckets")) {
            if (bucketName.equals(b.path("bucketName").asText())) {
                this.bucketId = b.path("bucketId").asText();
                break;
            }
        }
        if (bucketId == null) {
            throw new IOExceptionB2("El bucket '" + bucketName + "' no existe en la cuenta B2.");
        }
        log.info("[BACKUP B2] Autenticado. Bucket {} = {}", bucketName, bucketId);
    }

    private JsonNode postJson(String url, com.fasterxml.jackson.databind.JsonNode body) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", accountToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(MAPPER.writeValueAsString(body)))
                .build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOExceptionB2("POST " + url + " devolvió HTTP " + response.statusCode()
                    + ": " + truncar(response.body()));
        }
        return MAPPER.readTree(response.body());
    }

    private static String sha1Hex(File archivo) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        try (java.io.FileInputStream fis = new java.io.FileInputStream(archivo)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = fis.read(buffer)) != -1) {
                md.update(buffer, 0, read);
            }
        }
        StringBuilder hex = new StringBuilder();
        for (byte b : md.digest()) {
            hex.append(String.format("%02x", b));
        }
        return hex.toString();
    }

    private static String quitarExtensionEnc(String nombre) {
        return nombre.endsWith(".enc") ? nombre.substring(0, nombre.length() - 4) : nombre;
    }

    private static String truncar(String s) {
        if (s == null) return "";
        return s.length() > 300 ? s.substring(0, 300) + "…" : s;
    }

    /** Error propio de la comunicación con B2. */
    static class IOExceptionB2 extends RuntimeException {
        IOExceptionB2(String mensaje) {
            super(mensaje);
        }
    }
}
