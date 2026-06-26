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
INSERT IGNORE INTO articulos_stock (id, esp_producto_id, cantidad, stock_minimo, created_at, updated_at) VALUES
(1, 1, 50, 10, NOW(), NOW()),
(2, 2, 30, 10, NOW(), NOW()),
(3, 3, 100, 10, NOW(), NOW()),
(4, 4, 20, 10, NOW(), NOW()),
(5, 5, 60, 10, NOW(), NOW());

INSERT IGNORE INTO esp_usuarios (id, activo, password, username) VALUES
(1, 1, '$2a$10$ZoyPuSsTfLPetCn1SJmW.eWzrD3Otan/DnE5eIh4C8KGTQDZ0P3eW', 'admin');

-- =========================
-- DATOS DE PRUEBA PARA DASHBOARD
-- =========================

-- Ventas de prueba (junio 2026)
INSERT IGNORE INTO ventas (id, fecha_hora, total, id_sesion_caja, creado_por_usuario, created_at, updated_at) VALUES
(100, '2026-06-01 10:30:00', 5000.00, 1, 1, NOW(), NOW()),
(101, '2026-06-01 15:00:00', 3000.00, 1, 1, NOW(), NOW()),
(102, '2026-06-02 11:00:00', 8000.00, 1, 1, NOW(), NOW()),
(103, '2026-06-03 09:30:00', 2000.00, 1, 1, NOW(), NOW()),
(104, '2026-06-05 14:00:00', 10000.00, 1, 1, NOW(), NOW());

-- Líneas de venta
INSERT IGNORE INTO lineas_venta (id, id_venta, codigo_producto, cantidad, subtotal, precio_unitario, created_at, updated_at) VALUES
(100, 100, 'PROD-001', 10, 1000.00, 100.00, NOW(), NOW()),
(101, 100, 'PROD-002', 5, 1252.50, 250.50, NOW(), NOW()),
(102, 101, 'PROD-003', 20, 1505.00, 75.25, NOW(), NOW()),
(103, 102, 'PROD-001', 30, 3000.00, 100.00, NOW(), NOW()),
(104, 102, 'PROD-005', 25, 3768.75, 150.75, NOW(), NOW()),
(105, 103, 'PROD-004', 5, 1600.00, 320.00, NOW(), NOW()),
(106, 104, 'PROD-003', 50, 3762.50, 75.25, NOW(), NOW()),
(107, 104, 'PROD-002', 15, 3757.50, 250.50, NOW(), NOW());

-- Pagos de ventas
INSERT IGNORE INTO pagos_venta (id, venta_id, monto, metodo, created_at, updated_at) VALUES
(100, 100, 5000.00, 'EFECTIVO', NOW(), NOW()),
(101, 101, 3000.00, 'TRANSFERENCIA', NOW(), NOW()),
(102, 102, 8000.00, 'EFECTIVO', NOW(), NOW()),
(103, 103, 2000.00, 'MERCADO_PAGO', NOW(), NOW()),
(104, 104, 10000.00, 'EFECTIVO', NOW(), NOW());

-- Movimientos financieros
INSERT IGNORE INTO movimientos_financieros (id, tipo, monto, metodo_pago, categoria, descripcion, fecha_hora, pago_id, created_at, updated_at) VALUES
(100, 'INGRESO', 5000.00, 'EFECTIVO', 'VENTA', 'Venta de productos - ID: 100', '2026-06-01 10:30:00', 100, NOW(), NOW()),
(101, 'INGRESO', 3000.00, 'TRANSFERENCIA', 'VENTA', 'Venta de productos - ID: 101', '2026-06-01 15:00:00', 101, NOW(), NOW()),
(102, 'INGRESO', 8000.00, 'EFECTIVO', 'VENTA', 'Venta de productos - ID: 102', '2026-06-02 11:00:00', 102, NOW(), NOW()),
(103, 'INGRESO', 2000.00, 'MERCADO_PAGO', 'VENTA', 'Venta de productos - ID: 103', '2026-06-03 09:30:00', 103, NOW(), NOW()),
(104, 'INGRESO', 10000.00, 'EFECTIVO', 'VENTA', 'Venta de productos - ID: 104', '2026-06-05 14:00:00', 104, NOW(), NOW()),
(105, 'EGRESO', 1500.00, 'EFECTIVO', 'SERVICIO', 'Pago de servicios', '2026-06-01 18:00:00', NULL, NOW(), NOW()),
(106, 'EGRESO', 3000.00, 'TRANSFERENCIA', 'PROVEEDOR', 'Pago a proveedor', '2026-06-03 12:00:00', NULL, NOW(), NOW()),
(107, 'EGRESO', 2000.00, 'EFECTIVO', 'ALQUILER', 'Pago de alquiler', '2026-06-05 10:00:00', NULL, NOW(), NOW());

-- Actualizar stock para simular productos con stock bajo
UPDATE articulos_stock SET cantidad = 3 WHERE id = 4;
UPDATE articulos_stock SET cantidad = 0 WHERE id = 5;