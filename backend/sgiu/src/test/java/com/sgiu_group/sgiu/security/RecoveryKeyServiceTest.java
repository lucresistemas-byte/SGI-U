package com.sgiu_group.sgiu.security;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.Base64;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * UT-01..UT-10 y ARC-01..ARC-12: generación, persistencia, validación y
 * degradación controlada de la clave de recuperación de la instalación.
 */
class RecoveryKeyServiceTest {

    /** Base64 de 32 bytes: "0123456789abcdef0123456789abcdef". */
    private static final String CLAVE_TEST = "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=";

    @TempDir
    Path tempDir;

    private Path rutaClave;

    @BeforeEach
    void preparar() {
        rutaClave = tempDir.resolve("sgiu-recovery.key");
        System.setProperty("sgiu.recovery.keyPath", rutaClave.toString());
    }

    @AfterEach
    void limpiar() {
        System.clearProperty("sgiu.recovery.keyPath");
    }

    private RecoveryKeyService servicio() {
        return new RecoveryKeyService();
    }

    @Test
    @DisplayName("UT-01 / ARC-01 / ARC-10: genera una clave Base64 de 32 bytes y crea el archivo")
    void init_sinArchivo_generaClaveBase64De32BytesYCreaElArchivo() throws Exception {
        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.isReady()).isTrue();
        assertThat(rutaClave).exists();

        byte[] bytes = Base64.getDecoder().decode(Files.readString(rutaClave).trim());
        assertThat(bytes).hasSize(32);
        assertThat(servicio.coincide(Files.readString(rutaClave).trim())).isTrue();
    }

    @Test
    @DisplayName("UT-02 / ARC-02 / ARC-03: al reiniciar se reutiliza la misma clave")
    void init_segundaInstancia_reutilizaLaMismaClave() throws Exception {
        RecoveryKeyService primera = servicio();
        primera.init();
        String claveGuardada = Files.readString(rutaClave).trim();

        RecoveryKeyService segunda = servicio();
        segunda.init();

        assertThat(segunda.isReady()).isTrue();
        assertThat(segunda.coincide(claveGuardada)).isTrue();
        assertThat(rutaClave).exists();
    }

    @Test
    @DisplayName("UT-03: la clave correcta coincide")
    void coincide_claveCorrecta_devuelveTrue() throws Exception {
        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.coincide(Files.readString(rutaClave).trim())).isTrue();
    }

    @Test
    @DisplayName("UT-04: una clave incorrecta no coincide")
    void coincide_claveIncorrecta_devuelveFalse() throws Exception {
        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.coincide("otra-clave-totalmente-diferente")).isFalse();
    }

    @Test
    @DisplayName("UT-05: una cadena vacía no coincide")
    void coincide_claveVacia_devuelveFalse() throws Exception {
        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.coincide("")).isFalse();
        assertThat(servicio.coincide("   ")).isFalse();
    }

    @Test
    @DisplayName("UT-06 / ARC-11: sin inicializar el servicio no coincide y no está listo")
    void coincide_sinInit_devuelveFalse() {
        RecoveryKeyService servicio = servicio();

        assertThat(servicio.isReady()).isFalse();
        assertThat(servicio.coincide(CLAVE_TEST)).isFalse();
    }

    @Test
    @DisplayName("UT-07: una clave configurada por propiedad tiene prioridad y no crea archivo")
    void init_conClaveConfigurada_usaEsaClaveYNoCreaArchivo() {
        RecoveryKeyService servicio = servicio();
        ReflectionTestUtils.setField(servicio, "configuredKey", CLAVE_TEST);
        servicio.init();

        assertThat(servicio.isReady()).isTrue();
        assertThat(servicio.coincide(CLAVE_TEST)).isTrue();
        assertThat(rutaClave).doesNotExist();
    }

    @Test
    @DisplayName("UT-08 / ARC-07: si no se puede escribir el archivo, la app arranca pero la recuperación no está disponible")
    void init_sinPermisoDeEscritura_noLanzaYNoEstaListo() throws Exception {
        Path bloqueo = tempDir.resolve("bloqueo");
        Files.writeString(bloqueo, "no soy un directorio");
        System.setProperty("sgiu.recovery.keyPath", bloqueo.resolve("clave.key").toString());

        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.isReady()).isFalse();
        assertThat(servicio.coincide(CLAVE_TEST)).isFalse();
    }

    @Test
    @DisplayName("UT-09: un archivo de clave vacío no se acepta ni se sobrescribe")
    void init_archivoVacio_noEstaListoYNoSobrescribe() throws Exception {
        Files.writeString(rutaClave, "");

        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.isReady()).isFalse();
        assertThat(Files.readString(rutaClave)).isEmpty();
    }

    @Test
    @DisplayName("ARC-09: un archivo de clave corrupto no se acepta ni se sobrescribe")
    void init_archivoCorrupto_noEstaListoYNoSobrescribe() throws Exception {
        String contenidoCorrupto = "no-es-base64-valido!!!";
        Files.writeString(rutaClave, contenidoCorrupto);

        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.isReady()).isFalse();
        assertThat(Files.readString(rutaClave)).isEqualTo(contenidoCorrupto);
    }

    @Test
    @DisplayName("UT-10: crea los directorios que falten en la ruta de la clave")
    void init_directorioInexistente_creaDirectorios() {
        Path rutaAnidada = tempDir.resolve("a/b/c/sgiu-recovery.key");
        System.setProperty("sgiu.recovery.keyPath", rutaAnidada.toString());

        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.isReady()).isTrue();
        assertThat(rutaAnidada).exists();
    }

    @Test
    @DisplayName("ARC-04: la ruta personalizada se usa para crear el archivo")
    void init_conRutaPersonalizada_usaEsaRuta() {
        Path rutaPersonalizada = tempDir.resolve("custom/sgiu-recovery.key");
        System.setProperty("sgiu.recovery.keyPath", rutaPersonalizada.toString());

        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(rutaPersonalizada).exists();
    }

    @Test
    @DisplayName("ARC-05: con LOCALAPPDATA usa %LOCALAPPDATA%/SGI-U/sgiu-recovery.key")
    void resolverRuta_conLocalAppData_usaLocalAppData() {
        Path ruta = RecoveryKeyService.resolverRuta(null, "/tmp/LocalAppData", "/home/test");

        assertThat(ruta.toString()).isEqualTo("/tmp/LocalAppData/SGI-U/sgiu-recovery.key");
    }

    @Test
    @DisplayName("ARC-06: sin LOCALAPPDATA usa el home como fallback")
    void resolverRuta_sinLocalAppData_usaUserHome() {
        Path ruta = RecoveryKeyService.resolverRuta(null, "", "/home/test");

        assertThat(ruta.toString()).isEqualTo("/home/test/SGI-U/sgiu-recovery.key");
    }

    @Test
    @DisplayName("ARC-04: la ruta configurada tiene prioridad sobre el default")
    void resolverRuta_conRutaConfigurada_usaEsaRuta() {
        Path ruta = RecoveryKeyService.resolverRuta("/custom/clave", "/tmp/LocalAppData", "/home/test");

        assertThat(ruta.toString()).isEqualTo("/custom/clave");
    }

    @Test
    @DisplayName("ARC-08: si la ruta de la clave es un directorio, la recuperación queda no disponible")
    void init_siLaRutaEsUnDirectorio_noLanzaYNoEstaListo() throws Exception {
        Path directorio = tempDir.resolve("directorio");
        Files.createDirectory(directorio);
        System.setProperty("sgiu.recovery.keyPath", directorio.toString());

        RecoveryKeyService servicio = servicio();
        servicio.init();

        assertThat(servicio.isReady()).isFalse();
    }

    @Test
    @DisplayName("ARC-12: en sistemas POSIX el archivo de clave queda con permisos rw-------")
    void init_enPosix_aplicaPermisosRestrictivos() throws Exception {
        assumeTrue(FileSystems.getDefault().supportedFileAttributeViews().contains("posix"));

        RecoveryKeyService servicio = servicio();
        servicio.init();

        Set<PosixFilePermission> permisos = Files.getPosixFilePermissions(rutaClave);
        assertThat(permisos).containsExactlyInAnyOrder(
                PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE);
    }
}
