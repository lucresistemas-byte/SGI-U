package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.backup.BackupDumpJob;
import com.sgiu_group.sgiu.backup.BackupUploader;
import com.sgiu_group.sgiu.models.dtos.BackupEstadoDTO;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BackupControllerTest {

    @Mock
    private BackupDumpJob backupDumpJob;

    @Mock
    private BackupUploader backupUploader;

    @Mock
    private ConfiguracionNegocioRepository configuracionRepository;

    @InjectMocks
    private BackupController backupController;

    @TempDir
    Path tempDir;

    @Test
    void obtenerEstadoBackup_sinArchivosLocales_devuelveCritico() {
        when(backupDumpJob.obtenerUltimoRespaldoLocal()).thenReturn(Optional.empty());
        when(backupUploader.isConfigurado()).thenReturn(false);

        ResponseEntity<BackupEstadoDTO> response = backupController.obtenerEstadoBackup();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        BackupEstadoDTO body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getEstado()).isEqualTo("CRITICO");
        assertThat(body.getUltimoBackupTimestamp()).isNull();
        assertThat(body.getHorasDesdeUltimo()).isNull();
        assertThat(body.getUltimoArchivo()).isNull();
        assertThat(body.getAlmacenamientoRemoto()).isEqualTo("NO_CONFIGURADO");
        assertThat(body.getMensaje()).contains("Peligro");
    }

    @Test
    void obtenerEstadoBackup_conBackupReciente_devuelveAlDia() throws Exception {
        LocalDateTime haceDosHoras = LocalDateTime.now().minusHours(2);
        String nombreArchivo = "sgiu_" + haceDosHoras.format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".sql.gz.enc";
        File archivo = tempDir.resolve(nombreArchivo).toFile();
        Files.writeString(archivo.toPath(), "mock-backup-bytes");

        when(backupDumpJob.obtenerUltimoRespaldoLocal()).thenReturn(Optional.of(archivo));
        when(backupUploader.isConfigurado()).thenReturn(true);

        ResponseEntity<BackupEstadoDTO> response = backupController.obtenerEstadoBackup();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        BackupEstadoDTO body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getEstado()).isEqualTo("AL_DIA");
        assertThat(body.getHorasDesdeUltimo()).isBetween(1L, 3L);
        assertThat(body.getUltimoArchivo()).isEqualTo(nombreArchivo);
        assertThat(body.getAlmacenamientoRemoto()).isEqualTo("CONFIGURADO");
        assertThat(body.getMensaje()).contains("Respaldo al día");
    }

    @Test
    void obtenerEstadoBackup_conBackupMayorA24Horas_devuelveDesactualizado() throws Exception {
        LocalDateTime haceTresDias = LocalDateTime.now().minusDays(3);
        String nombreArchivo = "sgiu_" + haceTresDias.format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".sql.gz.enc";
        File archivo = tempDir.resolve(nombreArchivo).toFile();
        Files.writeString(archivo.toPath(), "mock-backup-bytes");

        when(backupDumpJob.obtenerUltimoRespaldoLocal()).thenReturn(Optional.of(archivo));
        when(backupUploader.isConfigurado()).thenReturn(false);

        ResponseEntity<BackupEstadoDTO> response = backupController.obtenerEstadoBackup();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        BackupEstadoDTO body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getEstado()).isEqualTo("DESACTUALIZADO");
        assertThat(body.getHorasDesdeUltimo()).isGreaterThanOrEqualTo(71L);
        assertThat(body.getUltimoArchivo()).isEqualTo(nombreArchivo);
        assertThat(body.getAlmacenamientoRemoto()).isEqualTo("LOCAL_ONLY");
        assertThat(body.getMensaje()).contains("Atención: El último respaldo tiene más de 24 horas");
    }
}
