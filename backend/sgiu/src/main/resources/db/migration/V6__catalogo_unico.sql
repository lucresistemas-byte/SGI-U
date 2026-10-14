-- =============================================================================
-- Etapa 3: catálogo único. Materias primas, insumos y reventa + materia prima
-- pasan a esp_productos (tipos MATERIA_PRIMA, INSUMO, REVENTA_MATERIA_PRIMA,
-- con sus códigos MP-, INS-, RMP-). Su stock vive en articulos_stock, en la
-- unidad base de su familia. Las recetas apuntan a esp_productos.
-- Solo hay datos de demo: se mueven tal cual y se borra materias_primas.
-- =============================================================================

-- Unidades, costo y presentación de compra (solo artículos de materia prima).
ALTER TABLE esp_productos
    ADD COLUMN familia ENUM('PESO','VOLUMEN','LONGITUD','UNIDAD') NULL AFTER unidad_medida,
    ADD COLUMN costo_unidad_base DECIMAL(14,4) NULL AFTER familia,
    ADD COLUMN presentacion_descripcion VARCHAR(100) NULL AFTER costo_unidad_base,
    ADD COLUMN presentacion_cantidad DECIMAL(14,3) NULL AFTER presentacion_descripcion,
    ADD COLUMN presentacion_unidad ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA') NULL
        AFTER presentacion_cantidad,
    ADD COLUMN presentacion_precio DECIMAL(12,2) NULL AFTER presentacion_unidad,
    -- Reventa + materia prima: unidad en que se vende ("Caja", 100 g en unidad base).
    ADD COLUMN venta_unidad_nombre VARCHAR(50) NULL AFTER presentacion_precio,
    ADD COLUMN venta_unidad_contenido DECIMAL(14,3) NULL AFTER venta_unidad_nombre,
    -- true = el precio de venta se fijó a mano y no sigue al costo.
    ADD COLUMN precio_manual BIT(1) NOT NULL DEFAULT 0 AFTER precio_unitario;

-- Stock en unidad base (gramos, mililitros...): admite decimales.
UPDATE articulos_stock SET stock_minimo = 0 WHERE stock_minimo IS NULL;
ALTER TABLE articulos_stock
    MODIFY cantidad DECIMAL(14,3) NOT NULL,
    MODIFY stock_minimo DECIMAL(14,3) NOT NULL DEFAULT 0;

-- Materias primas → esp_productos (mismo código). La reventa + materia prima
-- se vende por su presentación de compra.
INSERT INTO esp_productos (created_at, updated_at, activo, codigo, nombre, tipo, vendible, version,
                           porcentaje_ganancia, precio_costo, precio_unitario, unidad_medida, familia,
                           costo_unidad_base, presentacion_descripcion, presentacion_cantidad,
                           presentacion_unidad, presentacion_precio, venta_unidad_nombre, venta_unidad_contenido)
SELECT m.created_at, m.updated_at, m.activo, m.codigo, m.nombre, m.tipo, 1, 0,
       0, 0, 0, m.unidad_medida, m.familia,
       m.costo_unidad_base, m.presentacion_descripcion, m.presentacion_cantidad,
       m.presentacion_unidad, m.presentacion_precio,
       CASE WHEN m.tipo = 'REVENTA_MATERIA_PRIMA' THEN COALESCE(m.presentacion_descripcion, 'Unidad') END,
       CASE WHEN m.tipo = 'REVENTA_MATERIA_PRIMA' THEN m.presentacion_cantidad * CASE m.presentacion_unidad
           WHEN 'KILO' THEN 1000 WHEN 'LITRO' THEN 1000 WHEN 'METRO' THEN 100 WHEN 'DOCENA' THEN 12 ELSE 1 END END
FROM materias_primas m
ORDER BY m.id;

INSERT INTO articulos_stock (created_at, updated_at, cantidad, stock_minimo, version, esp_producto_id)
SELECT m.created_at, m.updated_at, m.stock_actual, m.stock_minimo, 0, p.id
FROM materias_primas m
JOIN esp_productos p ON p.codigo = m.codigo;

-- Recetas: el componente es un artículo del catálogo.
ALTER TABLE recetas_detalles ADD COLUMN articulo_id BIGINT NULL AFTER receta_id;
UPDATE recetas_detalles d
JOIN materias_primas m ON m.id = d.materia_prima_id
JOIN esp_productos p ON p.codigo = m.codigo
SET d.articulo_id = p.id;

ALTER TABLE recetas_detalles DROP FOREIGN KEY fk_receta_detalle_materia_prima;
ALTER TABLE recetas_detalles
    DROP COLUMN materia_prima_id,
    MODIFY articulo_id BIGINT NOT NULL,
    ADD CONSTRAINT fk_receta_detalle_articulo FOREIGN KEY (articulo_id) REFERENCES esp_productos (id);

DROP TABLE materias_primas;

-- Los artículos de materia prima tienen familia y costo por unidad base; la
-- reventa + materia prima, además, su unidad de venta.
ALTER TABLE esp_productos
    ADD CONSTRAINT ck_articulo_materia_prima CHECK (
        tipo NOT IN ('MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA')
        OR (familia IS NOT NULL AND costo_unidad_base IS NOT NULL)),
    ADD CONSTRAINT ck_unidad_de_venta CHECK (
        tipo <> 'REVENTA_MATERIA_PRIMA'
        OR (venta_unidad_nombre IS NOT NULL AND venta_unidad_contenido > 0));
