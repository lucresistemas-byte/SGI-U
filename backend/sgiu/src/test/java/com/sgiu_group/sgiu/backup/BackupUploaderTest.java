package com.sgiu_group.sgiu.backup;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class BackupUploaderTest {

    private BackupUploader uploader;
    private S3Client mockS3Client;

    @BeforeEach
    void setUp() {
        uploader = new BackupUploader();
        mockS3Client = mock(S3Client.class);
        uploader.setS3Client(mockS3Client);

        ReflectionTestUtils.setField(uploader, "bucketName", "sgiu-sandra-pruebas");
        ReflectionTestUtils.setField(uploader, "endpoint", "https://s3.ca-east-006.backblazeb2.com");
        ReflectionTestUtils.setField(uploader, "region", "ca-east-006");
        ReflectionTestUtils.setField(uploader, "keyId", "006testKeyId");
        ReflectionTestUtils.setField(uploader, "applicationKey", "testAppKey");
    }

    @Test
    void subirABucket_archivoMenorA15KB_lanzaExcepcion(@TempDir Path tempDir) throws IOException {
        File smallFile = tempDir.resolve("sgiu_20261022_120000.sql.gz.enc").toFile();
        try (FileOutputStream fos = new FileOutputStream(smallFile)) {
            fos.write(new byte[100]); // 100 bytes < 15 KB
        }

        assertThatThrownBy(() -> uploader.subirABucket(smallFile, "CLIENTE-TEST"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("menor a 15 KB");
    }

    @Test
    void subirABucket_archivoValido_ejecutaPutObjectEnB2(@TempDir Path tempDir) throws IOException {
        File validFile = tempDir.resolve("sgiu_20261022_120000.sql.gz.enc").toFile();
        try (FileOutputStream fos = new FileOutputStream(validFile)) {
            fos.write(new byte[16000]); // 16 KB > 15 KB
        }

        when(mockS3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        String ubicacion = uploader.subirABucket(validFile, "CLIENTE-TEST");

        assertThat(ubicacion).isEqualTo("s3://sgiu-sandra-pruebas/dumps/CLIENTE-TEST/sgiu_20261022_120000.sql.gz.enc");

        ArgumentCaptor<PutObjectRequest> captor = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(mockS3Client, atLeastOnce()).putObject(captor.capture(), any(RequestBody.class));

        PutObjectRequest request = captor.getValue();
        assertThat(request.bucket()).isEqualTo("sgiu-sandra-pruebas");
        assertThat(request.key()).contains("dumps/CLIENTE-TEST/");
    }

    @Test
    void limpiarRemotos_conBackupsObsoletos_eliminaExcedentesDePolitica() {
        LocalDate hoy = LocalDate.now();
        // 1 backup reciente (hace 5 días)
        String reciente = "dumps/TEST/sgiu_" + hoy.minusDays(5).format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "_120000.sql.gz.enc";
        // 1 backup mensual conservado (hace 45 días)
        String mensual1 = "dumps/TEST/sgiu_" + hoy.minusDays(45).format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "_120000.sql.gz.enc";
        // 1 backup del mismo mes que debe ser eliminado (hace 46 días)
        String mensual2 = "dumps/TEST/sgiu_" + hoy.minusDays(46).format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "_120000.sql.gz.enc";
        // 1 backup con más de 12 meses que debe ser eliminado (hace 400 días)
        String muyAntiguo = "dumps/TEST/sgiu_" + hoy.minusDays(400).format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "_120000.sql.gz.enc";

        List<S3Object> objetos = List.of(
                S3Object.builder().key(reciente).build(),
                S3Object.builder().key(mensual1).build(),
                S3Object.builder().key(mensual2).build(),
                S3Object.builder().key(muyAntiguo).build()
        );

        when(mockS3Client.listObjectsV2(any(ListObjectsV2Request.class)))
                .thenReturn(ListObjectsV2Response.builder().contents(objetos).build());
        when(mockS3Client.deleteObjects(any(DeleteObjectsRequest.class)))
                .thenReturn(DeleteObjectsResponse.builder().build());

        int borrados = uploader.limpiarRemotos("TEST");

        assertThat(borrados).isGreaterThan(0);
        verify(mockS3Client, times(1)).deleteObjects(any(DeleteObjectsRequest.class));
    }
}
