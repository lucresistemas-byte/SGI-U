package com.sgiu_group.sgiu.backup;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.File;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * A6: la subida a Backblaze B2 usa la API nativa (authorize → list_buckets →
 * get_upload_url → upload_file); si el bucket responde error, NUNCA se emite
 * un éxito ficticio.
 */
class BackupUploaderB2Test {

    @TempDir
    Path tempDir;

    private HttpServer server;
    private String base;
    private record Subida(String nombre, String sha1, byte[] cuerpo) {}
    private final List<Subida> subidas = new CopyOnWriteArrayList<>();
    private final List<String> borrados = new CopyOnWriteArrayList<>();
    private final AtomicBoolean fallarUpload = new AtomicBoolean(false);

    @BeforeEach
    void levantarServidorB2() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        base = "http://127.0.0.1:" + server.getAddress().getPort();

        server.createContext("/b2api/v2/b2_authorize_account", ex -> responder(ex, 200,
                "{\"accountId\":\"acc1\",\"apiUrl\":\"" + base + "\",\"authorizationToken\":\"sesion-token\"}"));
        server.createContext("/b2api/v2/b2_list_buckets", ex -> responder(ex, 200,
                "{\"buckets\":[{\"bucketId\":\"bucket-123\",\"bucketName\":\"sgiu-backups\"}]}"));
        server.createContext("/b2api/v2/b2_get_upload_url", ex -> responder(ex, 200,
                "{\"uploadUrl\":\"" + base + "/upload\",\"authorizationToken\":\"upload-token\"}"));
        server.createContext("/upload", ex -> {
            if (fallarUpload.get()) {
                responder(ex, 500, "{\"status\":\"error\"}");
                return;
            }
            subidas.add(new Subida(
                    ex.getRequestHeaders().getFirst("X-Bz-File-Name"),
                    ex.getRequestHeaders().getFirst("X-Bz-Content-Sha1"),
                    ex.getRequestBody().readAllBytes()));
            responder(ex, 200, "{\"fileId\":\"f-1\",\"fileName\":\"ok\"}");
        });
        server.createContext("/b2api/v2/b2_list_file_names", ex -> responder(ex, 200,
                "{\"files\":["
                        + "{\"fileName\":\"dumps/CLI/viejo.sql.gz.enc\",\"fileId\":\"fv\",\"uploadTimestamp\":"
                        + (System.currentTimeMillis() - 40L * 24 * 3600 * 1000) + "},"
                        + "{\"fileName\":\"dumps/CLI/nuevo.sql.gz.enc\",\"fileId\":\"fn\",\"uploadTimestamp\":"
                        + System.currentTimeMillis() + "}]}"));
        server.createContext("/b2api/v2/b2_delete_file_version", ex -> {
            String cuerpo = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            borrados.add(cuerpo);
            responder(ex, 200, "{\"status\":\"delete\"}");
        });
        server.start();
    }

    @AfterEach
    void apagar() {
        server.stop(0);
    }

    private static void responder(com.sun.net.httpserver.HttpExchange ex, int codigo, String cuerpo)
            throws java.io.IOException {
        byte[] bytes = cuerpo.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json");
        ex.sendResponseHeaders(codigo, bytes.length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(bytes);
        }
    }

    private BackupUploader uploaderConfigurado() {
        BackupUploader uploader = new BackupUploader();
        ReflectionTestUtils.setField(uploader, "bucketName", "sgiu-backups");
        ReflectionTestUtils.setField(uploader, "apiUrlBase", base);
        ReflectionTestUtils.setField(uploader, "keyId", "k001");
        ReflectionTestUtils.setField(uploader, "applicationKey", "secret-key");
        return uploader;
    }

    @Test
    void subir_sinCredenciales_quedaSoloLocal() throws Exception {
        BackupUploader uploader = uploaderConfigurado();
        ReflectionTestUtils.setField(uploader, "keyId", "");
        ReflectionTestUtils.setField(uploader, "applicationKey", "");

        File dump = tempDir.resolve("solo-local.sql.gz.enc").toFile();
        Files.write(dump.toPath(), "bytes".getBytes(StandardCharsets.UTF_8));

        String ruta = uploader.subirABucket(dump, "CLI");

        assertThat(ruta).endsWith("(LOCAL_ONLY)");
        assertThat(subidas).isEmpty();
    }

    @Test
    void subir_conCredenciales_enviaElArchivoYSusChecksums() throws Exception {
        File dump = tempDir.resolve("sgiu_x.sql.gz.enc").toFile();
        byte[] contenido = "contenido cifrado".getBytes(StandardCharsets.UTF_8);
        Files.write(dump.toPath(), contenido);

        File shaEnc = tempDir.resolve("sgiu_x.sql.gz.enc.sha256").toFile();
        Files.write(shaEnc.toPath(), "aaa  sgiu_x.sql.gz.enc\n".getBytes(StandardCharsets.UTF_8));
        File shaGz = tempDir.resolve("sgiu_x.sql.gz.sha256").toFile();
        Files.write(shaGz.toPath(), "bbb  sgiu_x.sql.gz\n".getBytes(StandardCharsets.UTF_8));

        String ruta = uploaderConfigurado().subirABucket(dump, "CLI");

        assertThat(ruta).isEqualTo("b2://sgiu-backups/dumps/CLI/sgiu_x.sql.gz.enc");
        // Tres subidas: el .enc y los dos .sha256 (del .enc y del .gz).
        assertThat(subidas).hasSize(3);
        Subida enc = subidas.get(0);
        assertThat(enc.cuerpo()).isEqualTo(contenido);
        // SHA-1 real del archivo, en hex (lo exige la API de B2).
        assertThat(enc.sha1()).hasSize(40).matches("[0-9a-f]{40}");
        assertThat(enc.nombre()).contains("dumps%2FCLI%2F");
        assertThat(subidas.get(1).nombre()).endsWith(".enc.sha256");
        assertThat(subidas.get(2).nombre()).endsWith(".sql.gz.sha256");
    }

    @Test
    void subir_siElBucketRespondeError_lanzaExcepcion() throws Exception {
        fallarUpload.set(true);
        File dump = tempDir.resolve("fallido.sql.gz.enc").toFile();
        Files.write(dump.toPath(), "bytes".getBytes(StandardCharsets.UTF_8));

        assertThatThrownBy(() -> uploaderConfigurado().subirABucket(dump, "CLI"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Backblaze B2");
    }

    @Test
    void rotacionRemota_borraSoloLoViejo() {
        int borradosCount = uploaderConfigurado().limpiarRemotosMasAntiguos("CLI", 30);

        assertThat(borradosCount).isEqualTo(1);
        assertThat(borrados).hasSize(1);
        assertThat(borrados.get(0)).contains("viejo.sql.gz.enc");
    }

    @Test
    void listarBackups_incluyeLosArchivosEnc() throws Exception {
        Files.write(tempDir.resolve("a.sql.gz.enc"), "x".getBytes(StandardCharsets.UTF_8));
        Files.write(tempDir.resolve("b.sql.gz"), "x".getBytes(StandardCharsets.UTF_8));
        Files.write(tempDir.resolve("a.sql.gz.enc.sha256"), "x".getBytes(StandardCharsets.UTF_8));

        BackupUploader uploader = new BackupUploader() {
            @Override
            File carpetaBackups() {
                return tempDir.toFile();
            }
        };

        List<String> listado = uploader.listarBackups("CLI");
        assertThat(listado).containsExactlyInAnyOrder("a.sql.gz.enc", "b.sql.gz");
    }
}
