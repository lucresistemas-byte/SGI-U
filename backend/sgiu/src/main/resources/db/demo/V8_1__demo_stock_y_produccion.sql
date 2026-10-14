-- =============================================================================
-- Demo de la etapa 5 (stock y producción):
--   - Stock de materias primas e insumos para producir algunas tortas,
--     porciones y paquetes.
--   - Faltante: la Tarta de coco lleva 250 g de coco y quedan 380 g. Producir
--     2 tartas avisa "Faltan 120 g de Coco rallado: hay 380 g, se necesitan 500 g".
--   - Historial: un movimiento "Stock inicial (demo)" por artículo con stock.
-- =============================================================================

-- Tarta de coco: 250 g de coco por tarta.
UPDATE recetas_detalles SET cantidad = 0.25, unidad_medida = 'KILO', cantidad_base = 250 WHERE id = 2;
UPDATE articulos_stock s JOIN esp_productos p ON p.id = s.esp_producto_id
SET s.cantidad = 380, s.stock_minimo = 500 WHERE p.codigo = 'MP-0002';

-- Costo y precio de la tarta con la receta nueva (a $100, como CostosService).
UPDATE esp_productos p
JOIN (SELECT r.esp_producto_id,
             ROUND(ROUND(SUM(d.cantidad_base * a.costo_unidad_base) + r.costos_adicionales, 2) / r.rinde, 2) AS costo
      FROM recetas r
      JOIN recetas_detalles d ON d.receta_id = r.id
      JOIN esp_productos a ON a.id = d.articulo_id
      GROUP BY r.id, r.esp_producto_id, r.costos_adicionales, r.rinde) x ON x.esp_producto_id = p.id
SET p.precio_costo = x.costo,
    p.precio_unitario = CEILING(ROUND(x.costo * (1 + COALESCE(p.porcentaje_ganancia, 0) / 100), 6) / 100) * 100
WHERE p.codigo = 'ELA-0001';

-- Historial: el stock con que arranca la demo.
INSERT INTO movimientos_stock (articulo_id, tipo, cantidad, stock_resultante, motivo, fecha, usuario,
    created_at, updated_at)
SELECT s.esp_producto_id, 'AJUSTE', s.cantidad, s.cantidad, 'Stock inicial (demo)', NOW(6) - INTERVAL 1 DAY,
    'admin', NOW(6), NOW(6)
FROM articulos_stock s
WHERE s.cantidad <> 0;
