-- =============================================================================
-- Etapa 4: motor de precios.
--   - Modo de precio por artículo: MARGEN (costo × (1 + %)), MANUAL (precio de
--     Sandra, nunca por debajo del %) y COSTO_MAS_FIJO (paquetes: costo del
--     armado + monto fijo). Reemplaza a precio_manual.
--   - Las preparaciones base rinden en peso o volumen (rinde_unidad_medida) y
--     se usan como componente de otras recetas.
--   - Paquetes: su armado (insumos con cantidad y unidad).
--   - Historial de precios: cada cambio de costo o precio, con su causa.
-- =============================================================================

ALTER TABLE esp_productos
    ADD COLUMN modo_precio ENUM('MARGEN','MANUAL','COSTO_MAS_FIJO') NOT NULL DEFAULT 'MARGEN' AFTER precio_unitario,
    ADD COLUMN monto_fijo DECIMAL(10,2) NULL AFTER modo_precio;

UPDATE esp_productos SET modo_precio = 'MANUAL' WHERE precio_manual = 1;
UPDATE esp_productos SET modo_precio = 'COSTO_MAS_FIJO', monto_fijo = 0 WHERE tipo = 'PAQUETE';

ALTER TABLE esp_productos DROP COLUMN precio_manual;

-- Unidad del rinde: obligatoria en las preparaciones base (gramo, kilo,
-- mililitro, litro); los elaborados que se venden rinden en unidades/porciones.
ALTER TABLE recetas
    ADD COLUMN rinde_unidad_medida ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA') NULL
        AFTER rinde_unidad;

CREATE TABLE paquetes_armado (
    id            BIGINT        NOT NULL AUTO_INCREMENT,
    created_at    DATETIME(6)   NOT NULL,
    updated_at    DATETIME(6)   NOT NULL,
    paquete_id    BIGINT        NOT NULL,
    articulo_id   BIGINT        NOT NULL,
    cantidad      DECIMAL(14,3) NOT NULL,
    unidad_medida ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA') NOT NULL,
    cantidad_base DECIMAL(14,3) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_paquete_armado_paquete FOREIGN KEY (paquete_id) REFERENCES esp_productos (id),
    CONSTRAINT fk_paquete_armado_articulo FOREIGN KEY (articulo_id) REFERENCES esp_productos (id)
);

CREATE TABLE historial_precios (
    id                BIGINT        NOT NULL AUTO_INCREMENT,
    created_at        DATETIME(6)   NOT NULL,
    updated_at        DATETIME(6)   NOT NULL,
    articulo_id       BIGINT        NOT NULL,
    costo_anterior    DECIMAL(14,4),
    costo_nuevo       DECIMAL(14,4),
    precio_anterior   DECIMAL(10,2),
    precio_nuevo      DECIMAL(10,2),
    modo_precio       ENUM('MARGEN','MANUAL','COSTO_MAS_FIJO') NOT NULL,
    -- Qué lo disparó: "Cambio de costo de Chocolate cobertura (MP-0005)".
    causa             VARCHAR(255)  NOT NULL,
    causa_articulo_id BIGINT,
    fecha             DATETIME(6)   NOT NULL,
    usuario           VARCHAR(100),
    PRIMARY KEY (id),
    CONSTRAINT fk_historial_precio_articulo FOREIGN KEY (articulo_id) REFERENCES esp_productos (id),
    CONSTRAINT fk_historial_precio_causa FOREIGN KEY (causa_articulo_id) REFERENCES esp_productos (id)
);
CREATE INDEX ix_historial_precios_fecha ON historial_precios (fecha);
