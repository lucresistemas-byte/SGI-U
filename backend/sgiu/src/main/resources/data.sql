-- =========================
-- INSERT: ESPECIFICACIONES DE PRODUCTO
-- =========================
-- Se agrega la columna 'nombre' (CU02) y 'activo' (RN08)
INSERT IGNORE INTO esp_productos (id, codigo, nombre, precio_unitario, activo, created_at, updated_at) VALUES
(1, 'PROD-001', 'Arroz Integral 1kg', 100.00, 1, NOW(), NOW()),
(2, 'PROD-002', 'Leche Entera 1L', 250.50, 1, NOW(), NOW()),
(3, 'PROD-003', 'Cerveza Brahma', 75.25, 1, NOW(), NOW()),
(4, 'PROD-004', 'Carbon Vegetal 5kg', 320.00, 1, NOW(), NOW()),
(5, 'PROD-005', 'Coca-Cola', 150.75, 1, NOW(), NOW());

-- =========================
-- INSERT: STOCK INICIAL
-- =========================
-- Se asegura que los 5 productos tengan su registro de stock físico
INSERT IGNORE INTO articulos_stock (id, esp_producto_id, cantidad, created_at, updated_at) VALUES
(1, 1, 50, NOW(), NOW()),
(2, 2, 30, NOW(), NOW()),
(3, 3, 100, NOW(), NOW()),
(4, 4, 20, NOW(), NOW()),
(5, 5, 60, NOW(), NOW());