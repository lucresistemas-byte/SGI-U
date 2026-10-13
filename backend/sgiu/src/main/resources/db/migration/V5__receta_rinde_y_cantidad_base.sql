-- =============================================================================
-- Etapa 2: cada fila de receta guarda la cantidad en la unidad elegida y la
-- cantidad en unidad base (para el costo). La receta tiene un rinde (p. ej.
-- 8 porciones): el costo unitario del elaborado es costo de receta / rinde.
-- =============================================================================

ALTER TABLE recetas_detalles
    MODIFY cantidad DECIMAL(14,3) NOT NULL,
    ADD COLUMN cantidad_base DECIMAL(14,3) NOT NULL DEFAULT 0 AFTER unidad_medida;

-- Filas existentes (demo): CAJA no tiene familia y se toma como unidad.
UPDATE recetas_detalles SET unidad_medida = 'UNIDAD' WHERE unidad_medida = 'CAJA';
UPDATE recetas_detalles SET cantidad_base = cantidad * CASE unidad_medida
    WHEN 'KILO' THEN 1000 WHEN 'LITRO' THEN 1000 WHEN 'METRO' THEN 100 WHEN 'DOCENA' THEN 12 ELSE 1 END;

ALTER TABLE recetas_detalles ALTER COLUMN cantidad_base DROP DEFAULT;

ALTER TABLE recetas
    ADD COLUMN rinde DECIMAL(10,3) NOT NULL DEFAULT 1 AFTER costos_adicionales,
    ADD COLUMN rinde_unidad VARCHAR(30) NOT NULL DEFAULT 'unidades' AFTER rinde;
