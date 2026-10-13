-- Demo: una venta de hoy pagada con efectivo + tarjeta (pago mixto), para ver
-- el desglose por método en el dashboard y el balance.
INSERT INTO ventas (id, fecha_hora, total, id_sesion_caja, creado_por_usuario, created_at, updated_at) VALUES
(5, NOW(6) - INTERVAL 1 HOUR, 22700.00, 0, 0, NOW(6), NOW(6));

INSERT INTO lineas_venta (id, id_venta, codigo_producto, cantidad, precio_unitario, costo_unitario, subtotal, created_at, updated_at) VALUES
(9,  5, 2, 1, 21200.00, 10095.00, 21200.00, NOW(6), NOW(6)),
(10, 5, 5, 1,  1500.00,   900.00,  1500.00, NOW(6), NOW(6));

UPDATE articulos_stock SET cantidad = cantidad - 1 WHERE esp_producto_id IN (2, 5);

-- Un pago y un movimiento por método: Efectivo (1) y Tarjeta (3).
INSERT INTO pagos_venta (id, venta_id, monto, metodo_pago_id, created_at, updated_at) VALUES
(5, 5, 10000.00, 1, NOW(6), NOW(6)),
(6, 5, 12700.00, 3, NOW(6), NOW(6));

INSERT INTO movimientos_financieros (id, tipo, monto, metodo_pago_id, categoria, descripcion, fecha_hora, pago_id, created_at, updated_at) VALUES
(8, 'INGRESO', 10000.00, 1, 'VENTA', 'Venta de productos - ID: 5', NOW(6) - INTERVAL 1 HOUR, 5, NOW(6), NOW(6)),
(9, 'INGRESO', 12700.00, 3, 'VENTA', 'Venta de productos - ID: 5', NOW(6) - INTERVAL 1 HOUR, 6, NOW(6), NOW(6));
