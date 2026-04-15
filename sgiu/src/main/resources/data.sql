-- =========================
-- INSERT: ESPECIFICACIONES DE PRODUCTO (CATÁLOGO)
-- =========================

INSERT INTO esp_productos (id, codigo, precio_unitario, created_at, updated_at) VALUES
(1, 'PROD-001', 100.00, NOW(), NOW()),
(2, 'PROD-002', 250.50, NOW(), NOW()),
(3, 'PROD-003', 75.25, NOW(), NOW()),
(4, 'PROD-004', 320.00, NOW(), NOW()),
(5, 'PROD-005', 150.75, NOW(), NOW());

-- =========================
-- INSERT: STOCK INICIAL
-- =========================

INSERT INTO articulos_stock (id, esp_producto_id, cantidad, created_at, updated_at) VALUES
(1, 1, 50, NOW(), NOW()),
(2, 2, 30, NOW(), NOW()),
(3, 3, 100, NOW(), NOW()),
(4, 4, 20, NOW(), NOW()),
(5, 5, 60, NOW(), NOW());