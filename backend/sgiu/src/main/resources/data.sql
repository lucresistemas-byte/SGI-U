-- =========================
-- INSERT: CATEGORIAS DE PRODUCTO (MVP)
-- =========================
INSERT IGNORE INTO categorias (id, nombre, descripcion, activo, created_at, updated_at) VALUES
(1, 'Alimentos', 'Productos comestibles generales y secos', 1, NOW(), NOW()),
(2, 'Bebidas', 'Bebidas con y sin alcohol', 1, NOW(), NOW());

-- =========================
-- INSERT: CONFIGURACION DE NEGOCIO (MVP / B2)
-- =========================
INSERT IGNORE INTO configuracion_negocio (id, nombre_comercio, codigo_cliente, logo_path, direccion, telefono, descripcion, created_at, updated_at) VALUES
(1, 'SGI-U Almacén de Sandra', 'SGIU-SANDRA-001', NULL, 'Av. San Martín 1234', '343-5551234', 'Comercio minorista y punto de venta', NOW(), NOW());

-- =========================
-- INSERT: ESPECIFICACIONES DE PRODUCTO
-- =========================
INSERT IGNORE INTO esp_productos (id, codigo, nombre, precio_unitario, precio_costo, porcentaje_ganancia, unidad_medida, categoria_id, activo, created_at, updated_at) VALUES
(1, 'PROD-001', 'Arroz Integral 1kg', 100.00, 70.00, 42.86, 'KILO', 1, 1, NOW(), NOW()),
(2, 'PROD-002', 'Leche Entera 1L', 250.50, 180.00, 39.17, 'LITRO', 1, 1, NOW(), NOW()),
(3, 'PROD-003', 'Cerveza Brahma', 75.25, 50.00, 50.50, 'UNIDAD', 2, 1, NOW(), NOW()),
(4, 'PROD-004', 'Carbon Vegetal 5kg', 320.00, 220.00, 45.45, 'UNIDAD', 1, 1, NOW(), NOW()),
(5, 'PROD-005', 'Coca-Cola', 150.75, 100.00, 50.75, 'UNIDAD', 2, 1, NOW(), NOW());

-- =========================
-- INSERT: STOCK INICIAL
-- =========================
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

-- Líneas de venta con costo unitario congelado
INSERT IGNORE INTO lineas_venta (id, id_venta, codigo_producto, cantidad, subtotal, precio_unitario, costo_unitario, created_at, updated_at) VALUES
(100, 100, 'PROD-001', 10, 1000.00, 100.00, 70.00, NOW(), NOW()),
(101, 100, 'PROD-002', 5, 1252.50, 250.50, 180.00, NOW(), NOW()),
(102, 101, 'PROD-003', 20, 1505.00, 75.25, 50.00, NOW(), NOW()),
(103, 102, 'PROD-001', 30, 3000.00, 100.00, 70.00, NOW(), NOW()),
(104, 102, 'PROD-005', 25, 3768.75, 150.75, 100.00, NOW(), NOW()),
(105, 103, 'PROD-004', 5, 1600.00, 320.00, 220.00, NOW(), NOW()),
(106, 104, 'PROD-003', 50, 3762.50, 75.25, 50.00, NOW(), NOW()),
(107, 104, 'PROD-002', 15, 3757.50, 250.50, 180.00, NOW(), NOW());

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

-- =========================
-- INSERT: MATERIAS PRIMAS (INSUMOS) (EXTENSIÓN 1)
-- =========================
INSERT IGNORE INTO materias_primas (id, codigo, nombre, costo_unitario, unidad_medida, stock_actual, stock_minimo, esp_producto_id, activo, created_at, updated_at) VALUES
(1, 'MP-001', 'Arroz Crudo a Granel', 35.00, 'KILO', 500, 50, NULL, 1, NOW(), NOW()),
(2, 'MP-002', 'Bolsa de Empaque Biodegradable 1kg', 5.00, 'UNIDAD', 1000, 100, NULL, 1, NOW(), NOW()),
(3, 'MP-003', 'Etiqueta Adhesiva Sandra', 2.50, 'UNIDAD', 2000, 200, NULL, 1, NOW(), NOW());

-- =========================
-- INSERT: RECETAS Y COSTEO POR ELABORADO (EXTENSIÓN 1)
-- =========================
INSERT IGNORE INTO recetas (id, esp_producto_id, nombre, descripcion, costos_adicionales, activo, created_at, updated_at) VALUES
(1, 1, 'Receta Fraccionado Arroz Sandra', 'Fraccionado de arroz con empaque y etiqueta de marca', 5.00, 1, NOW(), NOW());

INSERT IGNORE INTO recetas_detalles (id, receta_id, materia_prima_id, cantidad, unidad_medida, created_at, updated_at) VALUES
(1, 1, 1, 1.000, 'KILO', NOW(), NOW()),
(2, 1, 2, 1.000, 'UNIDAD', NOW(), NOW()),
(3, 1, 3, 1.000, 'UNIDAD', NOW(), NOW());

-- =========================
-- INSERT: PEDIDOS CON SEÑA Y SALDO (EXTENSIÓN 2)
-- =========================
INSERT IGNORE INTO pedidos (id, cliente_nombre, cliente_telefono, descripcion, monto_total, senia, saldo, estado, fecha_entrega, activo, created_at, updated_at) VALUES
(1, 'Carlos Pérez', '343-5112233', '10 bolsas de Arroz Integral especial para evento', 1000.00, 300.00, 700.00, 'PENDIENTE', '2026-07-01 18:00:00', 1, NOW(), NOW()),
(2, 'Laura Gómez', '343-4998877', 'Pedido surtido aniversario', 5000.00, 5000.00, 0.00, 'PAGADO', '2026-06-25 12:00:00', 1, NOW(), NOW());

INSERT IGNORE INTO pedidos_abonos (id, pedido_id, monto, metodo_pago, nota, created_at, updated_at) VALUES
(1, 1, 300.00, 'EFECTIVO', 'Seña inicial del pedido', NOW(), NOW()),
(2, 2, 2500.00, 'TRANSFERENCIA', 'Seña inicial del 50%', NOW(), NOW()),
(3, 2, 2500.00, 'EFECTIVO', 'Cancelación total de saldo restante', NOW(), NOW());