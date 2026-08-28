package com.sgiu_group.sgiu;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

public class InstallationIdentity {

    private static final String FILE_NAME = "sgiu-installation.id";

    public static String getOrCreate() {
        Path filePath = resolveFilePath();
        try {
            if (Files.exists(filePath)) {
                String content = Files.readString(filePath, StandardCharsets.UTF_8).trim();
                if (!content.isEmpty()) {
                    return content;
                }
            }
            String newId = UUID.randomUUID().toString();
            Files.writeString(filePath, newId, StandardCharsets.UTF_8);
            return newId;
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer/crear el archivo de identidad de instalacion: " + filePath, e);
        }
    }

    private static Path resolveFilePath() {
        String userProfile = System.getenv("USERPROFILE");
        if (userProfile == null || userProfile.isBlank()) {
            userProfile = System.getProperty("user.home");
        }
        return Paths.get(userProfile, FILE_NAME);
    }
}