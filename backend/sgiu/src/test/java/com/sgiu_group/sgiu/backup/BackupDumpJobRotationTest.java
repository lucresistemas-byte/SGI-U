package com.sgiu_group.sgiu.backup;

import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class BackupDumpJobRotationTest {

    private BackupDumpJob dumpJob;
    private BackupUploader mockUploader;
    private ConfiguracionNegocioRepository mockConfigRepo;
    private EncryptionService mockEncryptionService;

    @BeforeEach
    void setUp() {
        mockUploader = mock(BackupUploader.class);
        mockConfigRepo = mock(ConfiguracionNegocioRepository.class);
        mockEncryptionService = mock(EncryptionService.class);

        dumpJob = new BackupDumpJob(mockUploader, mockConfigRepo, mockEncryptionService);
    }

    @Test
    void rotarBackupsLocales_eliminaArchivosViejos_sinTocarElActual(@TempDir Path tempDir) throws IOException {
        File dir = tempDir.toFile();

        // 1. Archivo actual recién generado
        File archivoActual = new File(dir, "sgiu_20261022_120000.sql.gz.enc");
        File shaActual = new File(dir, "sgiu_20261022_120000.sql.gz.enc.sha256");
        assertThat(archivoActual.createNewFile()).isTrue();
        assertThat(shaActual.createNewFile()).isTrue();

        // 2. Archivo antiguo (> 14 días)
        File archivoAntiguo = new File(dir, "sgiu_20260901_033000.sql.gz.enc");
        File shaAntiguo = new File(dir, "sgiu_20260901_033000.sql.gz.enc.sha256");
        assertThat(archivoAntiguo.createNewFile()).isTrue();
        assertThat(shaAntiguo.createNewFile()).isTrue();

        long tiempoAntiguo = System.currentTimeMillis() - (20L * 24 * 60 * 60 * 1000); // 20 días atrás
        assertThat(archivoAntiguo.setLastModified(tiempoAntiguo)).isTrue();
        assertThat(shaAntiguo.setLastModified(tiempoAntiguo)).isTrue();

        // Ejecutar rotación
        int borrados = dumpJob.rotarBackupsLocales(dir, archivoActual, 14);

        assertThat(borrados).isEqualTo(2);
        // El actual y su sha deben conservarse intactos
        assertThat(archivoActual.exists()).isTrue();
        assertThat(shaActual.exists()).isTrue();
        // Los antiguos deben haber sido purgados
        assertThat(archivoAntiguo.exists()).isFalse();
        assertThat(shaAntiguo.exists()).isFalse();
    }

    @Test
    void helperNaming_generaSufijosYPrefijosConsistentes() {
        LocalDateTime ahora = LocalDateTime.of(2026, 10, 22, 15, 30, 0);
        String prefijo = BackupDumpJob.generarPrefijoDia(ahora);
        String timestamp = BackupDumpJob.generarTimestamp(ahora);

        assertThat(prefijo).isEqualTo("sgiu_20261022");
        assertThat(timestamp).isEqualTo("20261022_153000");
    }
}
