-- =============================================================================
-- Demo de la etapa 2: presentaciones de compra reales, costos por unidad base,
-- recetas con unidades mixtas y rinde:
--   - "Porción de torta de chocolate" (rinde 8 porciones),
--   - "Torta de chocolate" entera por encargo (rinde 1),
--   - "Alfajor de maicena" (rinde 24 alfajores).
-- =============================================================================

-- Presentaciones de compra (costo por unidad base = precio / cantidad base).
UPDATE materias_primas SET unidad_medida = 'KILO', presentacion_descripcion = 'Bolsa 25 kg',
    presentacion_cantidad = 25, presentacion_unidad = 'KILO', presentacion_precio = 30000,
    costo_unidad_base = 1.2000 WHERE codigo = 'MP-0001';                       -- Harina 000
UPDATE materias_primas SET presentacion_descripcion = 'Bolsa 1 kg',
    presentacion_cantidad = 1, presentacion_unidad = 'KILO', presentacion_precio = 9000,
    costo_unidad_base = 9.0000 WHERE codigo = 'MP-0002';                       -- Coco rallado
UPDATE materias_primas SET presentacion_descripcion = 'Paquete 1 kg',
    presentacion_cantidad = 1, presentacion_unidad = 'KILO', presentacion_precio = 1300,
    costo_unidad_base = 1.3000 WHERE codigo = 'MP-0003';                       -- Azúcar
UPDATE materias_primas SET unidad_medida = 'UNIDAD', presentacion_descripcion = 'Docena',
    presentacion_cantidad = 1, presentacion_unidad = 'DOCENA', presentacion_precio = 3000,
    costo_unidad_base = 250.0000 WHERE codigo = 'MP-0004';                     -- Huevos
UPDATE materias_primas SET presentacion_descripcion = 'Barra 1 kg',
    presentacion_cantidad = 1, presentacion_unidad = 'KILO', presentacion_precio = 18000,
    costo_unidad_base = 18.0000 WHERE codigo = 'MP-0005';                      -- Chocolate cobertura
UPDATE materias_primas SET presentacion_descripcion = 'Pote 1 l',
    presentacion_cantidad = 1, presentacion_unidad = 'LITRO', presentacion_precio = 5500,
    costo_unidad_base = 5.5000 WHERE codigo = 'MP-0006';                       -- Crema de leche
UPDATE materias_primas SET presentacion_descripcion = 'Pan 500 g',
    presentacion_cantidad = 500, presentacion_unidad = 'GRAMO', presentacion_precio = 4750,
    costo_unidad_base = 9.5000 WHERE codigo = 'MP-0007';                       -- Manteca
UPDATE materias_primas SET presentacion_descripcion = 'Caja para torta',
    presentacion_cantidad = 1, presentacion_unidad = 'UNIDAD', presentacion_precio = 900,
    costo_unidad_base = 900.0000 WHERE codigo = 'INS-0001';                    -- Caja para torta
UPDATE materias_primas SET unidad_medida = 'METRO', presentacion_descripcion = 'Rollo 10 m',
    presentacion_cantidad = 10, presentacion_unidad = 'METRO', presentacion_precio = 3000,
    costo_unidad_base = 3.0000 WHERE codigo = 'INS-0002';                      -- Cinta de regalo
UPDATE materias_primas SET presentacion_descripcion = 'Plancha x 100',
    presentacion_cantidad = 100, presentacion_unidad = 'UNIDAD', presentacion_precio = 8000,
    costo_unidad_base = 80.0000 WHERE codigo = 'INS-0003';                     -- Sticker

-- Leche: sachet de 1 l a $1.500 ($1,5 el ml); 6 l en stock.
INSERT INTO materias_primas (id, codigo, tipo, familia, nombre, unidad_medida, costo_unidad_base,
    stock_actual, stock_minimo, presentacion_descripcion, presentacion_cantidad, presentacion_unidad,
    presentacion_precio, activo, created_at, updated_at) VALUES
(11, 'MP-0008', 'MATERIA_PRIMA', 'VOLUMEN', 'Leche entera', 'LITRO', 1.5000,
    6000, 2000, 'Sachet 1 l', 1, 'LITRO', 1500, 1, NOW(6), NOW(6));
UPDATE secuencias_codigo SET ultimo = 8 WHERE prefijo = 'MP';

-- Productos: la torta entera es por encargo; la porción y el alfajor se
-- venden por unidad.
UPDATE esp_productos SET nombre = 'Torta de chocolate (entera, por encargo)' WHERE codigo = 'ELA-0002';
UPDATE esp_productos SET nombre = 'Alfajor de maicena', porcentaje_ganancia = 150 WHERE codigo = 'ELA-0003';
INSERT INTO esp_productos (id, codigo, nombre, tipo, vendible, precio_costo, porcentaje_ganancia,
    precio_unitario, unidad_medida, categoria_id, activo, created_at, updated_at) VALUES
(8, 'ELA-0005', 'Porción de torta de chocolate', 'ELABORADO', 1, 0, 150.00, 0, 'UNIDAD', 1, 1, NOW(6), NOW(6));
INSERT INTO articulos_stock (id, esp_producto_id, cantidad, stock_minimo, created_at, updated_at) VALUES
(8, 8, 8, 4, NOW(6), NOW(6));
UPDATE secuencias_codigo SET ultimo = 5 WHERE prefijo = 'ELA';

-- Recetas: rinde y qué rinde.
UPDATE recetas SET rinde = 1,  rinde_unidad = 'tarta'        WHERE id = 1;
UPDATE recetas SET rinde = 1,  rinde_unidad = 'torta', nombre = 'Torta de chocolate entera' WHERE id = 2;
UPDATE recetas SET rinde = 24, rinde_unidad = 'alfajores', nombre = 'Alfajores de maicena', descripcion = 'Tanda de 24' WHERE id = 3;
UPDATE recetas SET rinde = 1,  rinde_unidad = 'preparación'  WHERE id = 4;
INSERT INTO recetas (id, esp_producto_id, nombre, descripcion, costos_adicionales, rinde, rinde_unidad, activo, created_at, updated_at) VALUES
(5, 8, 'Torta de chocolate en porciones', 'Una torta cortada en 8 porciones', 0.00, 8, 'porciones', 1, NOW(6), NOW(6));

-- Ingredientes con unidades mixtas (cantidad en su unidad y en unidad base).
DELETE FROM recetas_detalles;
INSERT INTO recetas_detalles (id, receta_id, materia_prima_id, cantidad, unidad_medida, cantidad_base, created_at, updated_at) VALUES
-- Tarta de coco
(1,  1, 1,  250,   'GRAMO',     250,  NOW(6), NOW(6)),
(2,  1, 2,  0.2,   'KILO',      200,  NOW(6), NOW(6)),
(3,  1, 3,  150,   'GRAMO',     150,  NOW(6), NOW(6)),
(4,  1, 4,  3,     'UNIDAD',    3,    NOW(6), NOW(6)),
(5,  1, 7,  100,   'GRAMO',     100,  NOW(6), NOW(6)),
-- Torta de chocolate entera (por encargo): con caja y cinta.
(6,  2, 1,  300,   'GRAMO',     300,  NOW(6), NOW(6)),
(7,  2, 3,  200,   'GRAMO',     200,  NOW(6), NOW(6)),
(8,  2, 4,  4,     'UNIDAD',    4,    NOW(6), NOW(6)),
(9,  2, 5,  250,   'GRAMO',     250,  NOW(6), NOW(6)),
(10, 2, 6,  300,   'MILILITRO', 300,  NOW(6), NOW(6)),
(11, 2, 7,  150,   'GRAMO',     150,  NOW(6), NOW(6)),
(12, 2, 11, 200,   'MILILITRO', 200,  NOW(6), NOW(6)),
(13, 2, 8,  1,     'UNIDAD',    1,    NOW(6), NOW(6)),
(14, 2, 9,  0.5,   'METRO',     50,   NOW(6), NOW(6)),
-- Alfajores de maicena (24)
(15, 3, 1,  0.25,  'KILO',      250,  NOW(6), NOW(6)),
(16, 3, 7,  200,   'GRAMO',     200,  NOW(6), NOW(6)),
(17, 3, 3,  150,   'GRAMO',     150,  NOW(6), NOW(6)),
(18, 3, 4,  0.25,  'DOCENA',    3,    NOW(6), NOW(6)),
(19, 3, 2,  50,    'GRAMO',     50,   NOW(6), NOW(6)),
-- Ganache (preparación base)
(20, 4, 5,  200,   'GRAMO',     200,  NOW(6), NOW(6)),
(21, 4, 6,  0.2,   'LITRO',     200,  NOW(6), NOW(6)),
-- Torta de chocolate en porciones (rinde 8)
(22, 5, 1,  300,   'GRAMO',     300,  NOW(6), NOW(6)),
(23, 5, 3,  200,   'GRAMO',     200,  NOW(6), NOW(6)),
(24, 5, 4,  4,     'UNIDAD',    4,    NOW(6), NOW(6)),
(25, 5, 5,  250,   'GRAMO',     250,  NOW(6), NOW(6)),
(26, 5, 6,  300,   'MILILITRO', 300,  NOW(6), NOW(6)),
(27, 5, 7,  150,   'GRAMO',     150,  NOW(6), NOW(6)),
(28, 5, 11, 200,   'MILILITRO', 200,  NOW(6), NOW(6));

-- Costo y precio de los elaborados: costo de receta / rinde, y precio con
-- su % de ganancia (lo mismo que calcula la aplicación).
UPDATE esp_productos p
JOIN (SELECT r.esp_producto_id,
             ROUND(ROUND(SUM(d.cantidad_base * m.costo_unidad_base) + r.costos_adicionales, 2) / r.rinde, 2) AS costo
      FROM recetas r
      JOIN recetas_detalles d ON d.receta_id = r.id
      JOIN materias_primas m ON m.id = d.materia_prima_id
      GROUP BY r.id, r.esp_producto_id, r.costos_adicionales, r.rinde) x ON x.esp_producto_id = p.id
SET p.precio_costo = x.costo,
    p.precio_unitario = ROUND(x.costo * (1 + COALESCE(p.porcentaje_ganancia, 0) / 100), 2);
