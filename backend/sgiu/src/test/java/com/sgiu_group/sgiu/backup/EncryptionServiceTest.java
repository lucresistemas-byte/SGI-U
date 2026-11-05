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
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * A8: cifrado AES-256-GCM de los dumps y carga de la clave en modo CLI.
 */
class EncryptionServiceTest {

    @TempDir
    Path tempDir;

    private Path clave;

    @BeforeEach
    void claveEnTemp() {
        clave = tempDir.resolve("test-backup.key");
        System.setProperty("sgiu.backup.encryption.keyPath", clave.toString());
    }

    @AfterEach
    void limpiarPropiedad() {
        System.clearProperty("sgiu.backup.encryption.keyPath");
    }

    @Test
    void cifrarYDescifrar_esUnRoundtrip() throws Exception {
        EncryptionService servicio = new EncryptionService();
        servicio.init();

        File origen = tempDir.resolve("dump.sql.gz").toFile();
        Files.write(origen.toPath(), "-- MariaDB dump contenido del volcado".getBytes(StandardCharsets.UTF_8));

        File cifrado = servicio.cifrar(origen);
        assertThat(cifrado.getName()).isEqualTo("dump.sql.gz.enc");
        assertThat(cifrado.length()).isGreaterThan(0);

        byte[] recuperado = servicio.descifrar(cifrado);
        assertThat(new String(recuperado, StandardCharsets.UTF_8))
                .isEqualTo("-- MariaDB dump contenido del volcado");
    }

    @Test
    void initSolaLectura_sinClave_lanzaErrorExplicativo() {
        EncryptionService servicio = new EncryptionService();
        assertThatThrownBy(servicio::initSolaLectura)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("No existe la clave maestra");
        assertThat(clave).doesNotExist();
    }

    @Test
    void initSolaLectura_conClave_previa_laCarga() throws Exception {
        EncryptionService generador = new EncryptionService();
        generador.init();
        assertThat(clave).exists();

        EncryptionService restaurador = new EncryptionService();
        restaurador.initSolaLectura();
        assertThat(restaurador.isReady()).isTrue();
    }
}
