package com.sgiu_group.sgiu.backup;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * A7/A8: el modo CLI --restore verifica SHA-256, descifra .enc y entrega el
 * .sql.gz listo; nunca toca la base de datos (eso lo hace el .bat).
 */
class BackupRestoreToolTest {

    @TempDir
    Path tempDir;

    private Path clave;

    @BeforeEach
    void claveEnTemp() {
        clave = tempDir.resolve("restore-test.key");
        System.setProperty("sgiu.backup.encryption.keyPath", clave.toString());
    }

    @AfterEach
    void limpiarPropiedad() {
        System.clearProperty("sgiu.backup.encryption.keyPath");
    }

    private File dumpDePrueba(String nombre) throws Exception {
        File f = tempDir.resolve(nombre).toFile();
        Files.write(f.toPath(),
                ("-- MariaDB dump 10.16\n-- Dump diario SGI-U\n" + "x".repeat(200))
                        .getBytes(StandardCharsets.UTF_8));
        return f;
    }

    private static void escribirSha(File archivo, String hex) throws Exception {
        Files.writeString(new File(archivo.getParentFile(), archivo.getName() + ".sha256").toPath(),
                hex + "  " + archivo.getName() + System.lineSeparator());
    }

    @Test
    void archivoInexistente_devuelve2() {
        assertThat(BackupRestoreTool.restaurar(tempDir.resolve("no-existe.sql.gz.enc").toString(), null))
                .isEqualTo(BackupRestoreTool.ARCHIVO_INEXISTENTE);
    }

    @Test
    void encDescifraOk_yVerificaElGzDescifrado() throws Exception {
        File gz = dumpDePrueba("sgiu_20261017_033000.sql.gz");
        String shaGz = BackupRestoreTool.sha256Hex(gz);
        EncryptionService servicio = new EncryptionService();
        servicio.init();
        File enc = servicio.cifrar(gz);
        gz.delete();

        String shaEnc = BackupRestoreTool.sha256Hex(enc);
        escribirSha(enc, shaEnc);

        // También el hermano del .gz original (así se verifica post-descifrado).
        File shaGzFile = new File(tempDir.toFile(), "sgiu_20261017_033000.sql.gz.sha256");
        Files.writeString(shaGzFile.toPath(), shaGz + "  sgiu_20261017_033000.sql.gz\n");

        int codigo = BackupRestoreTool.restaurar(enc.getAbsolutePath(), null);

        assertThat(codigo).isEqualTo(BackupRestoreTool.OK);
        File gzResultante = tempDir.resolve("sgiu_20261017_033000.sql.gz").toFile();
        assertThat(gzResultante).exists();
        assertThat(BackupRestoreTool.sha256Hex(gzResultante)).isEqualTo(shaGz);
    }

    @Test
    void archivoAlterado_devuelveHashDistinto_yNoDescifra() throws Exception {
        File gz = dumpDePrueba("alterado.sql.gz");
        EncryptionService servicio = new EncryptionService();
        servicio.init();
        File enc = servicio.cifrar(gz);
        gz.delete();

        escribirSha(enc, BackupRestoreTool.sha256Hex(enc));
        // Altera un byte del cifrado.
        byte[] bytes = Files.readAllBytes(enc.toPath());
        bytes[bytes.length - 1] ^= 0xFF;
        Files.write(enc.toPath(), bytes);

        int codigo = BackupRestoreTool.restaurar(enc.getAbsolutePath(), null);

        assertThat(codigo).isEqualTo(BackupRestoreTool.HASH_DISTINTO);
        assertThat(tempDir.resolve("alterado.sql.gz").toFile()).doesNotExist();
    }

    @Test
    void claveIncorrecta_devuelveDescifradoFallido() throws Exception {
        File gz = dumpDePrueba("con-otra-clave.sql.gz");
        EncryptionService servicio = new EncryptionService();
        servicio.init();
        File enc = servicio.cifrar(gz);

        // Otra instalación, otra clave.
        System.setProperty("sgiu.backup.encryption.keyPath",
                tempDir.resolve("otra-clave.key").toString());

        int codigo = BackupRestoreTool.restaurar(enc.getAbsolutePath(),
                BackupRestoreTool.sha256Hex(enc));

        assertThat(codigo).isEqualTo(BackupRestoreTool.DESCIFRADO_FALLIDO);
    }

    @Test
    void sqlGzPlano_conShaHermanoOk_devuelve0() throws Exception {
        File gz = dumpDePrueba("plano.sql.gz");
        escribirSha(gz, BackupRestoreTool.sha256Hex(gz));

        assertThat(BackupRestoreTool.restaurar(gz.getAbsolutePath(), null))
                .isEqualTo(BackupRestoreTool.OK);
    }

    @Test
    void sqlGzPlano_conShaEsperadoDistinto_devuelve3() throws Exception {
        File gz = dumpDePrueba("plano-malo.sql.gz");

        assertThat(BackupRestoreTool.restaurar(gz.getAbsolutePath(),
                "0".repeat(64)))
                .isEqualTo(BackupRestoreTool.HASH_DISTINTO);
    }
}
