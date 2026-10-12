-- =============================================================================
-- Los pagos guardan el método por clave foránea a metodos_pago (antes texto
-- libre: las ventas guardaban "1"/"2" en vez del método, M-3/E-22).
-- Solo hay datos de demo: los textos conocidos se pasan a su método y
-- cualquier otro queda como Efectivo.
-- =============================================================================

-- Ventas
ALTER TABLE pagos_venta ADD COLUMN metodo_pago_id BIGINT NULL;
UPDATE pagos_venta SET metodo_pago_id = CASE UPPER(REPLACE(TRIM(metodo), ' ', '_'))
    WHEN 'MERCADO_PAGO' THEN 2 WHEN '2' THEN 2
    WHEN 'TARJETA' THEN 3 WHEN '3' THEN 3
    WHEN 'TRANSFERENCIA' THEN 4 WHEN '4' THEN 4
    ELSE 1 END;
ALTER TABLE pagos_venta
    MODIFY metodo_pago_id BIGINT NOT NULL,
    ADD CONSTRAINT fk_pago_venta_metodo FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago (id),
    DROP COLUMN metodo;

-- Movimientos financieros (ventas y altas manuales)
ALTER TABLE movimientos_financieros ADD COLUMN metodo_pago_id BIGINT NULL;
UPDATE movimientos_financieros SET metodo_pago_id = CASE UPPER(REPLACE(TRIM(metodo_pago), ' ', '_'))
    WHEN 'MERCADO_PAGO' THEN 2 WHEN '2' THEN 2
    WHEN 'TARJETA' THEN 3 WHEN '3' THEN 3
    WHEN 'TRANSFERENCIA' THEN 4 WHEN '4' THEN 4
    ELSE 1 END;
ALTER TABLE movimientos_financieros
    MODIFY metodo_pago_id BIGINT NOT NULL,
    ADD CONSTRAINT fk_mov_financiero_metodo FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago (id),
    DROP COLUMN metodo_pago;

-- Señas y pagos de pedidos
ALTER TABLE pedidos_abonos ADD COLUMN metodo_pago_id BIGINT NULL;
UPDATE pedidos_abonos SET metodo_pago_id = CASE UPPER(REPLACE(TRIM(COALESCE(metodo_pago, '')), ' ', '_'))
    WHEN 'MERCADO_PAGO' THEN 2 WHEN '2' THEN 2
    WHEN 'TARJETA' THEN 3 WHEN '3' THEN 3
    WHEN 'TRANSFERENCIA' THEN 4 WHEN '4' THEN 4
    ELSE 1 END;
ALTER TABLE pedidos_abonos
    MODIFY metodo_pago_id BIGINT NOT NULL,
    ADD CONSTRAINT fk_pedido_abono_metodo FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago (id),
    DROP COLUMN metodo_pago;
