-- =============================================================================
-- Etapa 2: familias de unidades. Cada materia prima pertenece a una familia
-- (peso, volumen, longitud, unidades) y guarda su stock y su costo en la
-- unidad base (gramo, mililitro, centímetro, unidad). El costo sale de la
-- presentación de compra (p. ej. "Bolsa 25 kg" a $30.000), que se guarda.
-- Solo hay datos de demo: se convierten con los factores de cada unidad.
-- =============================================================================

-- Unidades nuevas (CAJA queda solo para productos).
ALTER TABLE materias_primas MODIFY unidad_medida
    ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA') NOT NULL;
ALTER TABLE recetas_detalles MODIFY unidad_medida
    ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA') NOT NULL;
ALTER TABLE esp_productos MODIFY unidad_medida
    ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA');

ALTER TABLE materias_primas
    ADD COLUMN familia ENUM('PESO','VOLUMEN','LONGITUD','UNIDAD') NOT NULL DEFAULT 'UNIDAD' AFTER tipo,
    ADD COLUMN costo_unidad_base DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER unidad_medida,
    ADD COLUMN presentacion_descripcion VARCHAR(100) NULL,
    ADD COLUMN presentacion_cantidad DECIMAL(14,3) NULL,
    ADD COLUMN presentacion_unidad ENUM('GRAMO','KILO','MILILITRO','LITRO','CENTIMETRO','METRO','UNIDAD','DOCENA','CAJA') NULL,
    ADD COLUMN presentacion_precio DECIMAL(12,2) NULL,
    MODIFY stock_actual DECIMAL(14,3) NOT NULL,
    MODIFY stock_minimo DECIMAL(14,3) NOT NULL;

-- CAJA no tiene familia: un insumo por caja se cuenta por unidad.
UPDATE materias_primas SET unidad_medida = 'UNIDAD' WHERE unidad_medida = 'CAJA';

UPDATE materias_primas SET familia = CASE unidad_medida
    WHEN 'GRAMO' THEN 'PESO' WHEN 'KILO' THEN 'PESO'
    WHEN 'MILILITRO' THEN 'VOLUMEN' WHEN 'LITRO' THEN 'VOLUMEN'
    WHEN 'CENTIMETRO' THEN 'LONGITUD' WHEN 'METRO' THEN 'LONGITUD'
    ELSE 'UNIDAD' END;

-- Factor a unidad base: kilo y litro 1000, metro 100, docena 12.
UPDATE materias_primas SET
    costo_unidad_base = costo_unitario / CASE unidad_medida
        WHEN 'KILO' THEN 1000 WHEN 'LITRO' THEN 1000 WHEN 'METRO' THEN 100 WHEN 'DOCENA' THEN 12 ELSE 1 END,
    stock_actual = stock_actual * CASE unidad_medida
        WHEN 'KILO' THEN 1000 WHEN 'LITRO' THEN 1000 WHEN 'METRO' THEN 100 WHEN 'DOCENA' THEN 12 ELSE 1 END,
    stock_minimo = stock_minimo * CASE unidad_medida
        WHEN 'KILO' THEN 1000 WHEN 'LITRO' THEN 1000 WHEN 'METRO' THEN 100 WHEN 'DOCENA' THEN 12 ELSE 1 END,
    presentacion_cantidad = 1,
    presentacion_unidad = unidad_medida,
    presentacion_precio = costo_unitario;

ALTER TABLE materias_primas
    ALTER COLUMN familia DROP DEFAULT,
    ALTER COLUMN costo_unidad_base DROP DEFAULT,
    DROP COLUMN costo_unitario;
