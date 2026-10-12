-- =============================================================================
-- Datos de demostración (solo perfil "demo"): una pastelería de ejemplo.
-- No son datos de Sandra. El usuario admin lo crea DataSeeder.
-- =============================================================================

INSERT INTO configuracion_negocio (id, nombre, codigo_cliente, direccion, telefono, descripcion, created_at, updated_at) VALUES
(1, 'Dulces Sandra (demo)', 'SGIU-DEMO-001', 'Av. Siempre Viva 742', '11-5555-0000', 'Pastelería, chocolatería y regalería', NOW(6), NOW(6));

INSERT INTO categorias (id, nombre, descripcion, activo, created_at, updated_at) VALUES
(1, 'Tortas y tartas', 'Tortas, tartas y postres', 1, NOW(6), NOW(6)),
(2, 'Chocolatería', 'Bombones y chocolates', 1, NOW(6), NOW(6)),
(3, 'Regalería', 'Cajas y paquetes de regalo', 1, NOW(6), NOW(6)),
(4, 'Bebidas', 'Bebidas para la venta', 1, NOW(6), NOW(6));

-- Elaborados (con receta), una preparación base y artículos de reventa.
INSERT INTO esp_productos (id, codigo, nombre, tipo, vendible, precio_costo, porcentaje_ganancia, precio_unitario, unidad_medida, categoria_id, activo, created_at, updated_at) VALUES
(1, 'ELA-0001', 'Tarta de coco',          'ELABORADO', 1,  4895.00, 120.00, 10800.00, 'UNIDAD', 1, 1, NOW(6), NOW(6)),
(2, 'ELA-0002', 'Torta de chocolate',     'ELABORADO', 1, 10095.00, 110.00, 21200.00, 'UNIDAD', 1, 1, NOW(6), NOW(6)),
(3, 'ELA-0003', 'Alfajores de maicena x12','ELABORADO', 1,  2120.00, 150.00,  5300.00, 'UNIDAD', 1, 1, NOW(6), NOW(6)),
(4, 'ELA-0004', 'Ganache de chocolate',   'ELABORADO', 0,  4700.00,   0.00,  4700.00, 'UNIDAD', 2, 1, NOW(6), NOW(6)),
(5, 'REV-0001', 'Coca-Cola 500 ml',       'REVENTA',   1,   900.00,  60.00,  1500.00, 'UNIDAD', 4, 1, NOW(6), NOW(6)),
(6, 'REV-0002', 'Agua mineral 500 ml',    'REVENTA',   1,   500.00,  80.00,   900.00, 'UNIDAD', 4, 1, NOW(6), NOW(6)),
(7, 'REV-0003', 'Caja de bombones 100 g', 'REVENTA',   1,  3500.00,  70.00,  6000.00, 'UNIDAD', 2, 1, NOW(6), NOW(6));

INSERT INTO articulos_stock (id, esp_producto_id, cantidad, stock_minimo, created_at, updated_at) VALUES
(1, 1, 4, 2, NOW(6), NOW(6)),
(2, 2, 2, 1, NOW(6), NOW(6)),
(3, 3, 6, 3, NOW(6), NOW(6)),
(4, 4, 0, 0, NOW(6), NOW(6)),
(5, 5, 24, 6, NOW(6), NOW(6)),
(6, 6, 24, 6, NOW(6), NOW(6)),
(7, 7, 10, 3, NOW(6), NOW(6));

-- Materias primas e insumos (en esp_productos a partir de la etapa 3).
INSERT INTO materias_primas (id, codigo, nombre, costo_unitario, unidad_medida, stock_actual, stock_minimo, activo, created_at, updated_at) VALUES
(1,  'MP-0001', 'Harina 000',          1200.00, 'KILO',   25, 5,  1, NOW(6), NOW(6)),
(2,  'MP-0002', 'Coco rallado',        9000.00, 'KILO',    5, 1,  1, NOW(6), NOW(6)),
(3,  'MP-0003', 'Azúcar',              1300.00, 'KILO',   20, 5,  1, NOW(6), NOW(6)),
(4,  'MP-0004', 'Huevos',               250.00, 'UNIDAD', 120, 30, 1, NOW(6), NOW(6)),
(5,  'MP-0005', 'Chocolate cobertura', 18000.00, 'KILO',    4, 1,  1, NOW(6), NOW(6)),
(6,  'MP-0006', 'Crema de leche',      5500.00, 'LITRO',   6, 2,  1, NOW(6), NOW(6)),
(7,  'MP-0007', 'Manteca',             9500.00, 'KILO',    5, 1,  1, NOW(6), NOW(6)),
(8,  'INS-0001', 'Caja para torta',     900.00, 'UNIDAD', 50, 10, 1, NOW(6), NOW(6)),
(9,  'INS-0002', 'Cinta de regalo',     300.00, 'METRO', 100, 20, 1, NOW(6), NOW(6)),
(10, 'INS-0003', 'Sticker Dulces Sandra', 80.00, 'UNIDAD', 200, 50, 1, NOW(6), NOW(6));

INSERT INTO recetas (id, esp_producto_id, nombre, descripcion, costos_adicionales, activo, created_at, updated_at) VALUES
(1, 1, 'Tarta de coco',        'Masa sablée y relleno de coco', 900.00, 1, NOW(6), NOW(6)),
(2, 2, 'Torta de chocolate',   'Bizcochuelo, crema y chocolate', 900.00, 1, NOW(6), NOW(6)),
(3, 3, 'Alfajores de maicena', 'Docena',                         300.00, 1, NOW(6), NOW(6)),
(4, 4, 'Ganache de chocolate', 'Preparación base para tortas',     0.00, 1, NOW(6), NOW(6));

INSERT INTO recetas_detalles (id, receta_id, materia_prima_id, cantidad, unidad_medida, created_at, updated_at) VALUES
(1,  1, 1, 0.250, 'KILO',   NOW(6), NOW(6)),
(2,  1, 2, 0.200, 'KILO',   NOW(6), NOW(6)),
(3,  1, 3, 0.150, 'KILO',   NOW(6), NOW(6)),
(4,  1, 4, 3.000, 'UNIDAD', NOW(6), NOW(6)),
(5,  1, 7, 0.100, 'KILO',   NOW(6), NOW(6)),
(6,  2, 1, 0.300, 'KILO',   NOW(6), NOW(6)),
(7,  2, 3, 0.200, 'KILO',   NOW(6), NOW(6)),
(8,  2, 4, 4.000, 'UNIDAD', NOW(6), NOW(6)),
(9,  2, 5, 0.250, 'KILO',   NOW(6), NOW(6)),
(10, 2, 6, 0.300, 'LITRO',  NOW(6), NOW(6)),
(11, 2, 7, 0.150, 'KILO',   NOW(6), NOW(6)),
(12, 3, 1, 0.200, 'KILO',   NOW(6), NOW(6)),
(13, 3, 7, 0.100, 'KILO',   NOW(6), NOW(6)),
(14, 3, 3, 0.100, 'KILO',   NOW(6), NOW(6)),
(15, 3, 4, 2.000, 'UNIDAD', NOW(6), NOW(6)),
(16, 4, 5, 0.200, 'KILO',   NOW(6), NOW(6)),
(17, 4, 6, 0.200, 'LITRO',  NOW(6), NOW(6));

-- Ventas de los últimos días (para el dashboard y el balance).
INSERT INTO ventas (id, fecha_hora, total, id_sesion_caja, creado_por_usuario, created_at, updated_at) VALUES
(1, NOW(6) - INTERVAL 3 DAY, 13800.00, 0, 0, NOW(6), NOW(6)),
(2, NOW(6) - INTERVAL 2 DAY, 21200.00, 0, 0, NOW(6), NOW(6)),
(3, NOW(6) - INTERVAL 1 DAY, 12200.00, 0, 0, NOW(6), NOW(6)),
(4, NOW(6) - INTERVAL 2 HOUR, 6900.00, 0, 0, NOW(6), NOW(6));

INSERT INTO lineas_venta (id, id_venta, codigo_producto, cantidad, precio_unitario, costo_unitario, subtotal, created_at, updated_at) VALUES
(1, 1, 1, 1, 10800.00,  4895.00, 10800.00, NOW(6), NOW(6)),
(2, 1, 5, 2,  1500.00,   900.00,  3000.00, NOW(6), NOW(6)),
(3, 2, 2, 1, 21200.00, 10095.00, 21200.00, NOW(6), NOW(6)),
(4, 3, 3, 1,  5300.00,  2120.00,  5300.00, NOW(6), NOW(6)),
(5, 3, 7, 1,  6000.00,  3500.00,  6000.00, NOW(6), NOW(6)),
(6, 3, 6, 1,   900.00,   500.00,   900.00, NOW(6), NOW(6)),
(7, 4, 7, 1,  6000.00,  3500.00,  6000.00, NOW(6), NOW(6)),
(8, 4, 6, 1,   900.00,   500.00,   900.00, NOW(6), NOW(6));

INSERT INTO pagos_venta (id, venta_id, monto, metodo, created_at, updated_at) VALUES
(1, 1, 13800.00, 'EFECTIVO',      NOW(6), NOW(6)),
(2, 2, 21200.00, 'TRANSFERENCIA', NOW(6), NOW(6)),
(3, 3, 12200.00, 'EFECTIVO',      NOW(6), NOW(6)),
(4, 4,  6900.00, 'TRANSFERENCIA', NOW(6), NOW(6));

INSERT INTO movimientos_financieros (id, tipo, monto, metodo_pago, categoria, descripcion, fecha_hora, pago_id, created_at, updated_at) VALUES
(1, 'INGRESO', 13800.00, 'EFECTIVO',      'VENTA',     'Venta de productos - ID: 1', NOW(6) - INTERVAL 3 DAY,  1,    NOW(6), NOW(6)),
(2, 'INGRESO', 21200.00, 'TRANSFERENCIA', 'VENTA',     'Venta de productos - ID: 2', NOW(6) - INTERVAL 2 DAY,  2,    NOW(6), NOW(6)),
(3, 'INGRESO', 12200.00, 'EFECTIVO',      'VENTA',     'Venta de productos - ID: 3', NOW(6) - INTERVAL 1 DAY,  3,    NOW(6), NOW(6)),
(4, 'INGRESO',  6900.00, 'TRANSFERENCIA', 'VENTA',     'Venta de productos - ID: 4', NOW(6) - INTERVAL 2 HOUR, 4,    NOW(6), NOW(6)),
(5, 'EGRESO',  45000.00, 'TRANSFERENCIA', 'COMPRA',    'Compra de chocolate y coco', NOW(6) - INTERVAL 4 DAY,  NULL, NOW(6), NOW(6)),
(6, 'EGRESO',  18000.00, 'EFECTIVO',      'SERVICIOS', 'Factura de luz',             NOW(6) - INTERVAL 2 DAY,  NULL, NOW(6), NOW(6)),
(7, 'EGRESO',  60000.00, 'TRANSFERENCIA', 'ALQUILER',  'Alquiler del local',         NOW(6) - INTERVAL 5 DAY,  NULL, NOW(6), NOW(6));

INSERT INTO pedidos (id, cliente_nombre, cliente_telefono, descripcion, monto_total, senia, saldo, estado, fecha_entrega, activo, created_at, updated_at) VALUES
(1, 'Laura Gómez', '11-4444-1234', 'Torta de chocolate 2 pisos, cumpleaños', 45000.00, 15000.00, 30000.00, 'PENDIENTE', NOW(6) + INTERVAL 3 DAY, 1, NOW(6), NOW(6)),
(2, 'Martín Ruiz', '11-3333-9876', 'Tarta de coco grande',                   12000.00, 12000.00,     0.00, 'PAGADO',    NOW(6) + INTERVAL 1 DAY, 1, NOW(6), NOW(6));

INSERT INTO pedidos_abonos (id, pedido_id, monto, metodo_pago, nota, created_at, updated_at) VALUES
(1, 1, 15000.00, 'TRANSFERENCIA', 'Seña inicial del pedido', NOW(6), NOW(6)),
(2, 2, 12000.00, 'EFECTIVO',      'Seña inicial del pedido', NOW(6), NOW(6));
