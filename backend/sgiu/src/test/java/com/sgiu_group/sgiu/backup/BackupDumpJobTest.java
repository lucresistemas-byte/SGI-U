package com.sgiu_group.sgiu.backup;

import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/**
 * A6: catch-up reconoce el .enc, la rotación local borra solo lo viejo, el
 * checksum se escribe en formato sha256sum y el puerto/base salen del URL.
 */
class BackupDumpJobTest {

    @TempDir
    Path tempDir;

    private BackupDumpJob jobConCarpeta(File carpeta) {
        BackupDumpJob job = new BackupDumpJob(
                mock(BackupUploader.class),
                mock(ConfiguracionNegocioRepository.class),
                mock(EncryptionService.class)) {
            @Override
            File carpetaBackups() {
                return carpeta;
            }
        };
        ReflectionTestUtils.setField(job, "dbUrl", "jdbc:mariadb://localhost:3307/sgiu_db");
        return job;
    }

    // ------------------------------------------------------------------
    //  Catch-up
    // ------------------------------------------------------------------

    @Test
    void catchUp_reconoceElEncDelDia() throws Exception {
        File hoy = tempDir.resolve("sgiu_20261017_033000.sql.gz.enc").toFile();
        Files.write(hoy.toPath(), "x".getBytes(StandardCharsets.UTF_8));

        BackupDumpJob job = jobConCarpeta(tempDir.toFile());
        assertThat(job.existeRespaldoDeHoy(tempDir.toFile(), "sgiu_20261017")).isTrue();
    }

    @Test
    void catchUp_reconoceElSqlGzPlanoDelDia() throws Exception {
        File hoy = tempDir.resolve("sgiu_20261017_010000.sql.gz").toFile();
        Files.write(hoy.toPath(), "x".getBytes(StandardCharsets.UTF_8));

        assertThat(jobConCarpeta(tempDir.toFile())
                .existeRespaldoDeHoy(tempDir.toFile(), "sgiu_20261017")).isTrue();
    }

    @Test
    void catchUp_ignoraLosRespaldosDeAyer() throws Exception {
        File ayer = tempDir.resolve("sgiu_20261016_033000.sql.gz.enc").toFile();
        Files.write(ayer.toPath(), "x".getBytes(StandardCharsets.UTF_8));

        assertThat(jobConCarpeta(tempDir.toFile())
                .existeRespaldoDeHoy(tempDir.toFile(), "sgiu_20261017")).isFalse();
    }

    @Test
    void catchUp_carpetaInexistente_noExisteRespaldo() {
        File inexistente = tempDir.resolve("no-existe").toFile();
        assertThat(jobConCarpeta(tempDir.toFile())
                .existeRespaldoDeHoy(inexistente, "sgiu_20261017")).isFalse();
    }

    // ------------------------------------------------------------------
    //  Rotación local (14 días)
    // ------------------------------------------------------------------

    @Test
    void rotacionLocal_borraSoloLoMasViejoQueElPlazo() throws Exception {
        File viejo = tempDir.resolve("sgiu_20260901_033000.sql.gz.enc").toFile();
        Files.write(viejo.toPath(), "viejo".getBytes(StandardCharsets.UTF_8));
        assertThat(viejo.setLastModified(System.currentTimeMillis() - 20L * 24 * 3600 * 1000)).isTrue();

        File reciente = tempDir.resolve("sgiu_20261017_033000.sql.gz.enc").toFile();
        Files.write(reciente.toPath(), "nuevo".getBytes(StandardCharsets.UTF_8));

        File shaViejo = tempDir.resolve("sgiu_20260901_033000.sql.gz.enc.sha256").toFile();
        Files.write(shaViejo.toPath(), "abc  sgiu_20260901_033000.sql.gz.enc\n".getBytes(StandardCharsets.UTF_8));
        assertThat(shaViejo.setLastModified(System.currentTimeMillis() - 20L * 24 * 3600 * 1000)).isTrue();

        int borrados = jobConCarpeta(tempDir.toFile()).rotarBackupsLocales(14);

        assertThat(borrados).isEqualTo(2);
        assertThat(viejo).doesNotExist();
        assertThat(shaViejo).doesNotExist();
        assertThat(reciente).exists();
    }

    @Test
    void rotacionLocal_ceroDias_noBorraNada() throws Exception {
        File f = tempDir.resolve("sgiu_20260901_033000.sql.gz.enc").toFile();
        Files.write(f.toPath(), "x".getBytes(StandardCharsets.UTF_8));
        assertThat(f.setLastModified(0)).isTrue();

        assertThat(jobConCarpeta(tempDir.toFile()).rotarBackupsLocales(0)).isZero();
        assertThat(f).exists();
    }

    // ------------------------------------------------------------------
    //  Checksum
    // ------------------------------------------------------------------

    @Test
    void checksum_seEscribeEnFormatoSha256sum() throws Exception {
        File enc = tempDir.resolve("sgiu_x.sql.gz.enc").toFile();
        Files.write(enc.toPath(), "contenido".getBytes(StandardCharsets.UTF_8));

        BackupDumpJob job = jobConCarpeta(tempDir.toFile());
        String sha = job.calcularSha256(enc);
        job.escribirChecksum(new File(enc.getParentFile(), enc.getName() + ".sha256"), sha);

        String linea = Files.readString(tempDir.resolve("sgiu_x.sql.gz.enc.sha256")).trim();
        assertThat(linea).isEqualTo(sha + "  sgiu_x.sql.gz.enc");
    }

    // ------------------------------------------------------------------
    //  Puerto y base desde spring.datasource.url
    // ------------------------------------------------------------------

    @Test
    void puerto_y_base_seExtraenDelUrlDeLaBd() {
        BackupDumpJob job = jobConCarpeta(tempDir.toFile());
        assertThat(job.extraerPuerto()).isEqualTo("3307");
        assertThat(job.extraerBaseDeDatos()).isEqualTo("sgiu_db");

        ReflectionTestUtils.setField(job, "dbUrl", "jdbc:mariadb://db:3306/sgiu_db?useSSL=false");
        assertThat(job.extraerPuerto()).isEqualTo("3306");
        assertThat(job.extraerBaseDeDatos()).isEqualTo("sgiu_db");
    }
}
