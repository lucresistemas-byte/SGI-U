-- V10: A2 - Idempotencia de venta.
--
-- Un reintento de red (o del ReintentoStock) con el mismo tokenIdempotencia
-- no debe generar una venta duplicada: el índice único garantiza una sola
-- fila por token, y el servicio devuelve la venta ya registrada.

ALTER TABLE ventas
    ADD COLUMN token_idempotencia VARCHAR(64) NULL;

CREATE UNIQUE INDEX ux_ventas_token_idempotencia
    ON ventas (token_idempotencia);
