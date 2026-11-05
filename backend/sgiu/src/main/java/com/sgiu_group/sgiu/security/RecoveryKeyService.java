package com.sgiu_group.sgiu.security;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermissions;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Clave de recuperación de la instalación: permite restablecer la contraseña
 * de cualquier usuario (incluido el único ADMIN) sin internet, sin email y
 * sin autenticación previa.
 * <p>
 * La clave son 32 bytes aleatorios codificados en Base64, generados la primera
 * vez y persistidos en {@code %LOCALAPPDATA%/SGI-U/sgiu-recovery.key} (nunca
 * se versiona). Si la clave viene configurada por propiedad
 * ({@code sgiu.recovery.key}) tiene prioridad y no se usa archivo.
 * <p>
 * Si el archivo existe pero está vacío o corrupto, la clave NO se acepta NI se
 * sobrescribe: rotar la clave en silencio invalidaría la que el usuario guardó.
 * En ese caso hay que borrar el archivo para que se genere una nueva.
 */
@Slf4j
@Service
public class RecoveryKeyService {

    private static final int KEY_BYTES = 32;
    private static final String FILE_NAME = "sgiu-recovery.key";

    /** Tiene prioridad sobre el archivo (tests y soporte). */
    @Value("${sgiu.recovery.key:}")
    private String configuredKey;

    @Value("${sgiu.recovery.keyPath:}")
    private String keyPathConfig;

    private volatile String key;

    @PostConstruct
    public void init() {
        try {
            if (configuredKey != null && !configuredKey.isBlank()) {
                key = validarClave(configuredKey.trim());
                log.info("[RECUPERACION] Clave de recuperación configurada por propiedad (no se usa archivo).");
                return;
            }
            key = cargarOCrearArchivo();
            log.info("[RECUPERACION] Clave de recuperación disponible en {}", resolveKeyPath());
        } catch (Exception e) {
            // La aplicación debe arrancar aunque la recuperación no esté disponible.
            key = null;
            log.error("[RECUPERACION] No se pudo inicializar la clave de recuperación: {}", e.getMessage(), e);
        }
    }

    /**
     * Compara la clave candidata con la de la instalación en tiempo constante
     * ({@link MessageDigest#isEqual}). Devuelve false si el servicio no está
     * inicializado o la candidata es vacía.
     */
    public boolean coincide(String candidata) {
        if (key == null || candidata == null || candidata.isBlank()) {
            return false;
        }
        return MessageDigest.isEqual(
                key.getBytes(StandardCharsets.UTF_8),
                candidata.trim().getBytes(StandardCharsets.UTF_8));
    }

    /** true si el servicio tiene una clave cargada y lista. */
    public boolean isReady() {
        return key != null;
    }

    /** Ruta efectiva del archivo de clave; null si la clave viene configurada. */
    public Path rutaDeLaClave() {
        if (configuredKey != null && !configuredKey.isBlank()) {
            return null;
        }
        return resolveKeyPath();
    }

    String cargarOCrearArchivo() throws Exception {
        Path keyPath = resolveKeyPath();
        if (Files.exists(keyPath)) {
            String contenido = Files.readString(keyPath, StandardCharsets.UTF_8).trim();
            return validarClave(contenido);
        }

        String nueva = generarClave();
        Files.createDirectories(keyPath.getParent());
        Files.writeString(keyPath, nueva, StandardCharsets.UTF_8);
        aplicarPermisosRestrictivos(keyPath);
        log.warn("[RECUPERACION] Nueva clave de recuperación generada en {}. "
                + "GUARDA ESTE ARCHIVO: sin él no se puede restablecer una contraseña.", keyPath);
        return nueva;
    }

    /** Valida Base64 estándar de exactamente 32 bytes y devuelve la clave trimeda. */
    private static String validarClave(String encoded) {
        try {
            byte[] bytes = Base64.getDecoder().decode(encoded);
            if (bytes.length != KEY_BYTES) {
                throw new IllegalArgumentException(
                        "La clave debe representar " + KEY_BYTES + " bytes y representa " + bytes.length);
            }
            return encoded;
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                    "La clave de recuperación no es un Base64 válido de " + KEY_BYTES + " bytes", e);
        }
    }

    private static String generarClave() {
        byte[] bytes = new byte[KEY_BYTES];
        new SecureRandom().nextBytes(bytes);
        return Base64.getEncoder().encodeToString(bytes);
    }

    /** En sistemas POSIX el archivo queda rw-------; en Windows no aplica. */
    private static void aplicarPermisosRestrictivos(Path keyPath) {
        try {
            Files.setPosixFilePermissions(keyPath, PosixFilePermissions.fromString("rw-------"));
        } catch (UnsupportedOperationException | IOException e) {
            log.debug("[RECUPERACION] No se pudieron aplicar permisos restrictivos a {}: {}", keyPath, e.getMessage());
        }
    }

    private Path resolveKeyPath() {
        if (keyPathConfig != null && !keyPathConfig.isBlank()) {
            return Path.of(keyPathConfig);
        }
        // Permite apuntar a otra clave sin Spring (mismo patrón que EncryptionService).
        String sistema = System.getProperty("sgiu.recovery.keyPath");
        if (sistema != null && !sistema.isBlank()) {
            return Path.of(sistema);
        }
        return resolverRuta(null, System.getenv("LOCALAPPDATA"), System.getProperty("user.home"));
    }

    /** Resolución de ruta testeable (package-private). */
    static Path resolverRuta(String keyPathConfigOverride, String localAppData, String userHome) {
        if (keyPathConfigOverride != null && !keyPathConfigOverride.isBlank()) {
            return Path.of(keyPathConfigOverride);
        }
        String base = (localAppData != null && !localAppData.isBlank()) ? localAppData : userHome;
        return Path.of(base, "SGI-U", FILE_NAME);
    }
}
