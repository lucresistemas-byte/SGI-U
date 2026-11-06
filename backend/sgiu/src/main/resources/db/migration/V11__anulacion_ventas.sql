-- V11: Anulación de ventas (MUST R-15).
--
-- Permite anular una venta registrando motivo, usuario y fecha de anulación.
-- La anulación revierte stock y movimientos de caja sin borrar el registro histórico.

ALTER TABLE ventas
    ADD COLUMN anulada BIT(1) NOT NULL DEFAULT 0,
    ADD COLUMN motivo_anulacion VARCHAR(255) NULL,
    ADD COLUMN fecha_hora_anulacion DATETIME(6) NULL,
    ADD COLUMN anulado_por_usuario VARCHAR(100) NULL;

ALTER TABLE movimientos_stock
    MODIFY tipo ENUM('COMPRA','AJUSTE','MERMA','PRODUCCION','CONSUMO_PRODUCCION','VENTA','ANULACION_VENTA') NOT NULL;

CREATE INDEX ix_ventas_anulada_fecha ON ventas (anulada, fecha_hora);
