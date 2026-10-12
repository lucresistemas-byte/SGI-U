-- =============================================================================
-- Métodos de pago configurables (Configuración → Métodos de pago).
-- Los iniciales son los que ofrecía el filtro del dashboard. "Efectivo" es
-- fijo: no se renombra ni se desactiva (con él se calcula el vuelto).
-- No se borran: se desactivan, y los registros históricos los conservan.
-- =============================================================================

CREATE TABLE metodos_pago (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    nombre     VARCHAR(50) NOT NULL,
    activo     BIT(1)      NOT NULL DEFAULT 1,
    fijo       BIT(1)      NOT NULL DEFAULT 0,
    orden      INT         NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_metodo_pago_nombre UNIQUE (nombre)
);

INSERT INTO metodos_pago (id, created_at, updated_at, nombre, activo, fijo, orden) VALUES
(1, NOW(6), NOW(6), 'Efectivo',      1, 1, 1),
(2, NOW(6), NOW(6), 'Mercado Pago',  1, 0, 2),
(3, NOW(6), NOW(6), 'Tarjeta',       1, 0, 3),
(4, NOW(6), NOW(6), 'Transferencia', 1, 0, 4);
