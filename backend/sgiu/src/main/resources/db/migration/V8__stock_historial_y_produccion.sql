-- =============================================================================
-- Etapa 5: stock, historial y producción por tanda.
--   - producciones: cada carga de stock de un elaborado o un paquete, con el
--     costo unitario congelado y lo que faltó (si se produjo igual).
--   - movimientos_stock: todo cambio de stock (compra, ajuste, merma,
--     producción, consumo de producción y venta), con cantidad firmada en
--     unidad base y el stock resultante.
-- El stock puede quedar negativo cuando Sandra confirma una producción con
-- faltantes.
-- =============================================================================

CREATE TABLE producciones (
    id              BIGINT        NOT NULL AUTO_INCREMENT,
    created_at      DATETIME(6)   NOT NULL,
    updated_at      DATETIME(6)   NOT NULL,
    articulo_id     BIGINT        NOT NULL,
    cantidad        DECIMAL(14,3) NOT NULL,
    -- Costo unitario del producto al producir (congelado).
    costo_unitario  DECIMAL(14,4) NOT NULL,
    con_faltantes   BIT(1)        NOT NULL DEFAULT 0,
    -- "Faltan 120 g de Coco rallado: hay 380 g, se necesitan 500 g; ..."
    faltantes       VARCHAR(2000),
    motivo          VARCHAR(255),
    fecha           DATETIME(6)   NOT NULL,
    usuario         VARCHAR(100),
    PRIMARY KEY (id),
    CONSTRAINT fk_produccion_articulo FOREIGN KEY (articulo_id) REFERENCES esp_productos (id)
);

CREATE TABLE movimientos_stock (
    id               BIGINT        NOT NULL AUTO_INCREMENT,
    created_at       DATETIME(6)   NOT NULL,
    updated_at       DATETIME(6)   NOT NULL,
    articulo_id      BIGINT        NOT NULL,
    tipo             ENUM('COMPRA','AJUSTE','MERMA','PRODUCCION','CONSUMO_PRODUCCION','VENTA') NOT NULL,
    -- En unidad base, con signo: + entra, − sale.
    cantidad         DECIMAL(14,3) NOT NULL,
    stock_resultante DECIMAL(14,3) NOT NULL,
    motivo           VARCHAR(255),
    produccion_id    BIGINT,
    venta_id         BIGINT,
    fecha            DATETIME(6)   NOT NULL,
    usuario          VARCHAR(100),
    PRIMARY KEY (id),
    CONSTRAINT fk_movimiento_stock_articulo FOREIGN KEY (articulo_id) REFERENCES esp_productos (id),
    CONSTRAINT fk_movimiento_stock_produccion FOREIGN KEY (produccion_id) REFERENCES producciones (id),
    CONSTRAINT fk_movimiento_stock_venta FOREIGN KEY (venta_id) REFERENCES ventas (id)
);
CREATE INDEX ix_movimientos_stock_articulo_fecha ON movimientos_stock (articulo_id, fecha);
