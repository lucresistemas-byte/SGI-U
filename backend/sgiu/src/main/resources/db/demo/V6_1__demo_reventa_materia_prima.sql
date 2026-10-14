-- =============================================================================
-- Demo de la etapa 3: una reventa + materia prima comprada por bulto.
--   "Caja de chocolate amargo 100 g": se compra el bulto de 12 cajas (1,2 kg)
--   a $27.000 → $22,50 el gramo, $2.250 la caja; se vende por caja con 60 %
--   de ganancia ($3.600). Stock: 3.650 g = 36 cajas + 50 g sueltos.
--   "Brownie" (rinde 12 porciones) usa 150 g de esa caja.
-- =============================================================================

INSERT INTO esp_productos (codigo, nombre, tipo, vendible, precio_costo, porcentaje_ganancia, precio_unitario,
    precio_manual, unidad_medida, familia, costo_unidad_base, presentacion_descripcion, presentacion_cantidad,
    presentacion_unidad, presentacion_precio, venta_unidad_nombre, venta_unidad_contenido, categoria_id, activo,
    created_at, updated_at) VALUES
('RMP-0001', 'Caja de chocolate amargo 100 g', 'REVENTA_MATERIA_PRIMA', 1, 2250.00, 60.00, 3600.00,
    0, 'GRAMO', 'PESO', 22.5000, 'Bulto de 12 cajas', 1.2, 'KILO', 27000.00, 'Caja', 100, 2, 1,
    NOW(6), NOW(6));
INSERT INTO articulos_stock (esp_producto_id, cantidad, stock_minimo, created_at, updated_at)
SELECT id, 3650, 1200, NOW(6), NOW(6) FROM esp_productos WHERE codigo = 'RMP-0001';
UPDATE secuencias_codigo SET ultimo = 1 WHERE prefijo = 'RMP';

-- Brownie: elaborado vendible, 12 porciones por tanda.
INSERT INTO esp_productos (codigo, nombre, tipo, vendible, precio_costo, porcentaje_ganancia, precio_unitario,
    unidad_medida, categoria_id, activo, created_at, updated_at) VALUES
('ELA-0006', 'Brownie', 'ELABORADO', 1, 0, 120.00, 0, 'UNIDAD', 2, 1, NOW(6), NOW(6));
INSERT INTO articulos_stock (esp_producto_id, cantidad, stock_minimo, created_at, updated_at)
SELECT id, 6, 3, NOW(6), NOW(6) FROM esp_productos WHERE codigo = 'ELA-0006';
UPDATE secuencias_codigo SET ultimo = 6 WHERE prefijo = 'ELA';

INSERT INTO recetas (esp_producto_id, nombre, descripcion, costos_adicionales, rinde, rinde_unidad, activo,
    created_at, updated_at)
SELECT id, 'Brownie', 'Tanda de 12 porciones', 0.00, 12, 'porciones', 1, NOW(6), NOW(6)
FROM esp_productos WHERE codigo = 'ELA-0006';

INSERT INTO recetas_detalles (receta_id, articulo_id, cantidad, unidad_medida, cantidad_base, created_at, updated_at)
SELECT r.id, a.id, x.cantidad, x.unidad, x.base, NOW(6), NOW(6)
FROM recetas r
JOIN esp_productos e ON e.id = r.esp_producto_id AND e.codigo = 'ELA-0006'
JOIN (SELECT 'RMP-0001' AS codigo, 150 AS cantidad, 'GRAMO' AS unidad, 150 AS base
      UNION ALL SELECT 'MP-0001', 100, 'GRAMO', 100
      UNION ALL SELECT 'MP-0003', 200, 'GRAMO', 200
      UNION ALL SELECT 'MP-0004', 3,   'UNIDAD', 3
      UNION ALL SELECT 'MP-0007', 150, 'GRAMO', 150) x
JOIN esp_productos a ON a.codigo = x.codigo;

-- Costo y precio del brownie: costo de receta / rinde, con su % de ganancia.
UPDATE esp_productos p
JOIN (SELECT r.esp_producto_id,
             ROUND(ROUND(SUM(d.cantidad_base * a.costo_unidad_base) + r.costos_adicionales, 2) / r.rinde, 2) AS costo
      FROM recetas r
      JOIN recetas_detalles d ON d.receta_id = r.id
      JOIN esp_productos a ON a.id = d.articulo_id
      GROUP BY r.id, r.esp_producto_id, r.costos_adicionales, r.rinde) x ON x.esp_producto_id = p.id
SET p.precio_costo = x.costo,
    p.precio_unitario = ROUND(x.costo * (1 + COALESCE(p.porcentaje_ganancia, 0) / 100), 2)
WHERE p.codigo = 'ELA-0006';
