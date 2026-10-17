package com.sgiu_group.sgiu;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Gestiona y persiste los secretos de la instalación (clave JWT, etc.)
 * aislándolos de archivos versionados en Git y generando claves seguras de 256 bits por instalación.
 */
public class InstallationSecrets {

    private static final String FILE_NAME = "sgiu-jwt.secret";

    public static String getOrCreateJwtSecret() {
        // 1. Variable de entorno explícita (mayor precedencia)
        String envSecret = System.getenv("SGIU_JWT_SECRET");
        if (envSecret != null && !envSecret.isBlank()) {
            return envSecret.trim();
        }

        // 2. Propiedad del sistema
        String propSecret = System.getProperty("sgiu.jwt.secret");
        if (propSecret != null && !propSecret.isBlank()) {
            return propSecret.trim();
        }

        // 3. Archivo persistente local en la máquina
        Path filePath = resolveFilePath();
        try {
            if (Files.exists(filePath)) {
                String content = Files.readString(filePath, StandardCharsets.UTF_8).trim();
                if (!content.isEmpty() && content.length() >= 32) {
                    return content;
                }
            }

            // Generar nuevo secreto criptográficamente seguro de 256 bits (32 bytes)
            SecureRandom random = new SecureRandom();
            byte[] bytes = new byte[32];
            random.nextBytes(bytes);
            String newSecret = Base64.getEncoder().encodeToString(bytes);

            if (filePath.getParent() != null && !Files.exists(filePath.getParent())) {
                Files.createDirectories(filePath.getParent());
            }

            Files.writeString(filePath, newSecret, StandardCharsets.UTF_8);
            return newSecret;
        } catch (IOException e) {
            // A2: sin secreto compartido hardcodeado. Si no se puede persistir,
            // se genera uno aleatorio solo para esta ejecución (se invalidan
            // los tokens al reiniciar, que es lo correcto si falla el disco).
            System.err.println("Advertencia: No se pudo persistir el secreto JWT en disco: " + e.getMessage());
            byte[] bytes = new byte[32];
            new SecureRandom().nextBytes(bytes);
            return Base64.getEncoder().encodeToString(bytes);
        }
    }

    private static Path resolveFilePath() {
        String localAppData = System.getenv("LOCALAPPDATA");
        if (localAppData != null && !localAppData.isBlank()) {
            return Paths.get(localAppData, "SGI-U", FILE_NAME);
        }
        String userProfile = System.getenv("USERPROFILE");
        if (userProfile == null || userProfile.isBlank()) {
            userProfile = System.getProperty("user.home");
        }
        return Paths.get(userProfile, FILE_NAME);
    }
}
