package com.sgiu_group.sgiu.backup;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * A8: Cifrado simétrico AES-256-GCM para backups antes de subirlos a Backblaze B2.
 * <p>
 * La clave maestra se genera la primera vez y se persiste en
 * {@code %LOCALAPPDATA%/SGI-U/sgiu-backup.key} (nunca se sube al repositorio).
 * Cada archivo cifrado lleva un IV aleatorio de 12 bytes prepended al ciphertext.
 */
@Slf4j
@Service
public class EncryptionService {

    private static final String ALGORITHM    = "AES/GCM/NoPadding";
    private static final int    GCM_IV_LEN   = 12;  // 96 bits recomendados para GCM
    private static final int    GCM_TAG_BITS = 128;  // authentication tag de 128 bits
    private static final int    KEY_SIZE     = 256;

    /** Permite sobreescribir la ruta de la clave desde configuración (tests). */
    @Value("${sgiu.backup.encryption.keyPath:}")
    private String keyPathConfig;

    private SecretKey masterKey;

    @PostConstruct
    public void init() {
        try {
            masterKey = loadOrCreateMasterKey();
            log.info("[CIFRADO A8] Clave maestra de backup cargada correctamente.");
        } catch (Exception e) {
            log.error("[CIFRADO A8] No se pudo inicializar la clave maestra: {}", e.getMessage(), e);
            throw new IllegalStateException("Error crítico: no se pudo preparar el cifrado de backups.", e);
        }
    }

    /**
     * Cifra {@code origen} con AES-256-GCM y escribe el resultado (IV + ciphertext) en {@code destino}.
     * El archivo destino tiene extensión {@code .enc}.
     *
     * @param origen  archivo .sql.gz a cifrar
     * @return        archivo .sql.gz.enc resultante (en la misma carpeta)
     */
    public File cifrar(File origen) throws Exception {
        File destino = new File(origen.getParent(), origen.getName() + ".enc");

        byte[] iv = new byte[GCM_IV_LEN];
        new SecureRandom().nextBytes(iv);

        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(Cipher.ENCRYPT_MODE, masterKey, new GCMParameterSpec(GCM_TAG_BITS, iv));

        try (FileInputStream fis = new FileInputStream(origen);
             FileOutputStream fos = new FileOutputStream(destino)) {

            // Escribe el IV al inicio del archivo cifrado (necesario para descifrar)
            fos.write(iv);

            byte[] plain = fis.readAllBytes();
            byte[] encrypted = cipher.doFinal(plain);
            fos.write(encrypted);
        }

        log.info("[CIFRADO A8] Archivo cifrado: {} → {} ({} bytes)",
                origen.getName(), destino.getName(), destino.length());
        return destino;
    }

    /**
     * Descifra {@code archivoCifrado} (IV + ciphertext) y devuelve el contenido en bytes.
     * Usado en el flujo de restauración.
     */
    public byte[] descifrar(File archivoCifrado) throws Exception {
        try (FileInputStream fis = new FileInputStream(archivoCifrado)) {
            byte[] iv = fis.readNBytes(GCM_IV_LEN);
            byte[] ciphertext = fis.readAllBytes();

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.DECRYPT_MODE, masterKey, new GCMParameterSpec(GCM_TAG_BITS, iv));
            return cipher.doFinal(ciphertext);
        }
    }

    // -----------------------------------------------------------------------
    //  Gestión de la clave maestra
    // -----------------------------------------------------------------------

    private SecretKey loadOrCreateMasterKey() throws Exception {
        Path keyPath = resolveKeyPath();
        if (Files.exists(keyPath)) {
            String encoded = Files.readString(keyPath, StandardCharsets.UTF_8).trim();
            byte[] decoded = Base64.getDecoder().decode(encoded);
            log.debug("[CIFRADO A8] Clave maestra leída desde {}", keyPath);
            return new SecretKeySpec(decoded, "AES");
        }

        // Genera nueva clave de 256 bits
        KeyGenerator kg = KeyGenerator.getInstance("AES");
        kg.init(KEY_SIZE, new SecureRandom());
        SecretKey newKey = kg.generateKey();

        Files.createDirectories(keyPath.getParent());
        Files.writeString(keyPath,
                Base64.getEncoder().encodeToString(newKey.getEncoded()),
                StandardCharsets.UTF_8);
        log.warn("[CIFRADO A8] Nueva clave maestra generada en {}. " +
                "GUARDA ESTE ARCHIVO: sin él no se pueden restaurar los backups.", keyPath);
        return newKey;
    }

    private Path resolveKeyPath() {
        if (keyPathConfig != null && !keyPathConfig.isBlank()) {
            return Path.of(keyPathConfig);
        }
        String localAppData = System.getenv("LOCALAPPDATA");
        if (localAppData == null || localAppData.isBlank()) {
            localAppData = System.getProperty("user.home");
        }
        return Path.of(localAppData, "SGI-U", "sgiu-backup.key");
    }

    /** Expone si el servicio fue inicializado correctamente (útil para health-check). */
    public boolean isReady() {
        return masterKey != null;
    }
}
