-- =============================================================================
-- Demo de la etapa 4 (motor de precios):
--   - "Ganache de chocolate" (ELA-0004) es una preparación base que rinde
--     800 g y se usa en la "Torta de chocolate (entera, por encargo)":
--     chocolate → ganache → torta.
--   - "Paquete día de la madre" (PAQ-0001): caja + cinta + papel de regalo +
--     monto fijo.
--   - "Caja de bombones 100 g" (REV-0003) con precio a mano.
--   - Todos los precios redondeados hacia arriba a $100 (lo mismo que calcula
--     CostosService).
-- =============================================================================

-- Papel de regalo: rollo de 5 m a $5.000 ($10 el centímetro).
INSERT INTO esp_productos (codigo, nombre, tipo, vendible, precio_costo, porcentaje_ganancia, precio_unitario,
    unidad_medida, familia, costo_unidad_base, presentacion_descripcion, presentacion_cantidad, presentacion_unidad,
    presentacion_precio, activo, created_at, updated_at) VALUES
('INS-0004', 'Papel de regalo', 'INSUMO', 1, 0, 0, 0, 'METRO', 'LONGITUD', 10.0000, 'Rollo 5 m', 5, 'METRO', 5000,
    1, NOW(6), NOW(6));
INSERT INTO articulos_stock (esp_producto_id, cantidad, stock_minimo, created_at, updated_at)
SELECT id, 2500, 500, NOW(6), NOW(6) FROM esp_productos WHERE codigo = 'INS-0004';
UPDATE secuencias_codigo SET ultimo = 4 WHERE prefijo = 'INS';

-- Ganache: 400 g de chocolate + 400 ml de crema, rinde 800 g.
UPDATE recetas SET rinde = 800, rinde_unidad = 'g', rinde_unidad_medida = 'GRAMO',
    descripcion = 'Preparación base: rinde 800 g' WHERE id = 4;
UPDATE recetas_detalles SET cantidad = 400, unidad_medida = 'GRAMO', cantidad_base = 400 WHERE id = 20;
UPDATE recetas_detalles SET cantidad = 0.4, unidad_medida = 'LITRO', cantidad_base = 400 WHERE id = 21;
UPDATE esp_productos SET familia = 'PESO', unidad_medida = 'GRAMO', porcentaje_ganancia = 0 WHERE codigo = 'ELA-0004';

-- La torta entera lleva 300 g de ganache.
INSERT INTO recetas_detalles (receta_id, articulo_id, cantidad, unidad_medida, cantidad_base, created_at, updated_at)
SELECT 2, id, 300, 'GRAMO', 300, NOW(6), NOW(6) FROM esp_productos WHERE codigo = 'ELA-0004';

-- Paquete día de la madre: caja (1 u) + cinta (1 m) + papel (1 m) + $1.550 fijos.
INSERT INTO esp_productos (codigo, nombre, tipo, vendible, precio_costo, porcentaje_ganancia, precio_unitario,
    modo_precio, monto_fijo, unidad_medida, categoria_id, activo, created_at, updated_at) VALUES
('PAQ-0001', 'Paquete día de la madre', 'PAQUETE', 1, 0, 0, 0, 'COSTO_MAS_FIJO', 1550.00, 'UNIDAD', 3, 1,
    NOW(6), NOW(6));
INSERT INTO articulos_stock (esp_producto_id, cantidad, stock_minimo, created_at, updated_at)
SELECT id, 5, 2, NOW(6), NOW(6) FROM esp_productos WHERE codigo = 'PAQ-0001';
UPDATE secuencias_codigo SET ultimo = 1 WHERE prefijo = 'PAQ';

INSERT INTO paquetes_armado (paquete_id, articulo_id, cantidad, unidad_medida, cantidad_base, created_at, updated_at)
SELECT p.id, a.id, x.cantidad, x.unidad, x.base, NOW(6), NOW(6)
FROM esp_productos p
JOIN (SELECT 'INS-0001' AS codigo, 1 AS cantidad, 'UNIDAD' AS unidad, 1 AS base
      UNION ALL SELECT 'INS-0002', 1, 'METRO', 100
      UNION ALL SELECT 'INS-0004', 1, 'METRO', 100) x
JOIN esp_productos a ON a.codigo = x.codigo
WHERE p.codigo = 'PAQ-0001';

-- Caja de bombones: precio a mano de $6.500 (con 70 % el mínimo es $6.000).
UPDATE esp_productos SET modo_precio = 'MANUAL', precio_unitario = 6500.00 WHERE codigo = 'REV-0003';

-- ---------------------------------------------------------------------------
-- Costos y precios con las reglas de la etapa 4 (orden: preparación base,
-- elaborados que se venden, reventa, paquetes). Precio = hacia arriba a $100.
-- ---------------------------------------------------------------------------

-- Ganache: costo por gramo = costo de la receta / 800 g; costo por gramo como precio de costo.
UPDATE esp_productos p
JOIN (SELECT r.esp_producto_id,
             ROUND(ROUND(SUM(d.cantidad_base * a.costo_unidad_base) + r.costos_adicionales, 2) / r.rinde, 4) AS cub
      FROM recetas r
      JOIN recetas_detalles d ON d.receta_id = r.id
      JOIN esp_productos a ON a.id = d.articulo_id
      WHERE r.id = 4
      GROUP BY r.id, r.esp_producto_id, r.costos_adicionales, r.rinde) x ON x.esp_producto_id = p.id
SET p.costo_unidad_base = x.cub, p.precio_costo = ROUND(x.cub, 2), p.precio_unitario = 0;

-- Elaborados que se venden: costo de receta / rinde; precio con su %, a $100.
UPDATE esp_productos p
JOIN (SELECT r.esp_producto_id,
             ROUND(ROUND(SUM(d.cantidad_base * a.costo_unidad_base) + r.costos_adicionales, 2) / r.rinde, 2) AS costo
      FROM recetas r
      JOIN recetas_detalles d ON d.receta_id = r.id
      JOIN esp_productos a ON a.id = d.articulo_id
      GROUP BY r.id, r.esp_producto_id, r.costos_adicionales, r.rinde) x ON x.esp_producto_id = p.id
SET p.precio_costo = x.costo,
    p.precio_unitario = CEILING(ROUND(x.costo * (1 + COALESCE(p.porcentaje_ganancia, 0) / 100), 6) / 100) * 100
WHERE p.tipo = 'ELABORADO' AND p.vendible = 1;

-- Reventa y reventa + materia prima con margen: a $100.
UPDATE esp_productos
SET precio_unitario = CEILING(ROUND(precio_costo * (1 + COALESCE(porcentaje_ganancia, 0) / 100), 6) / 100) * 100
WHERE tipo IN ('REVENTA', 'REVENTA_MATERIA_PRIMA') AND modo_precio = 'MARGEN';

-- Paquete: costo del armado + monto fijo, a $100.
UPDATE esp_productos p
JOIN (SELECT a.paquete_id, ROUND(SUM(a.cantidad_base * i.costo_unidad_base), 2) AS costo
      FROM paquetes_armado a JOIN esp_productos i ON i.id = a.articulo_id
      GROUP BY a.paquete_id) x ON x.paquete_id = p.id
SET p.precio_costo = x.costo,
    p.precio_unitario = CEILING((x.costo + p.monto_fijo) / 100) * 100;
