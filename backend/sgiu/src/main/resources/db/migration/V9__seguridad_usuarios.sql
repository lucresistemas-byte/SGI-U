-- =============================================================================
-- V9: Tarea A2 - Seguridad de usuarios y roles.
-- Agrega campos 'rol' y 'requiere_cambio_password' a la tabla 'esp_usuarios'.
-- Permite segmentación de privilegios (ADMIN, CAJERO) y exige cambio obligatorio
-- de la contraseña por defecto en el primer uso.
-- =============================================================================

ALTER TABLE esp_usuarios
    ADD COLUMN rol VARCHAR(20) NOT NULL DEFAULT 'ADMIN',
    ADD COLUMN requiere_cambio_password BIT(1) NOT NULL DEFAULT 0;

-- Si existe el usuario de fábrica 'admin', se le exige cambio de clave en primer uso.
UPDATE esp_usuarios
SET requiere_cambio_password = 1
WHERE username = 'admin';
