-- V10: Soporte para Idempotencia en Ventas (OWASP API6:2023 / RFC 9110)
-- Permite que el frontend envíe un token único por transacción para evitar cobros dobles o duplicación de inventario

ALTER TABLE ventas ADD COLUMN token_idempotencia VARCHAR(100) NULL UNIQUE;
