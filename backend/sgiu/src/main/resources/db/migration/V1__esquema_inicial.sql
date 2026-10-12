-- =============================================================================
-- SGI-U - Esquema inicial (etapa 1 del modelo de productos).
-- Ver docs/MODELO_PRODUCTOS.md. Hibernate valida contra este esquema
-- (ddl-auto: validate); cualquier cambio va en una migración nueva.
-- =============================================================================

CREATE TABLE categorias (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    created_at  DATETIME(6)  NOT NULL,
    updated_at  DATETIME(6)  NOT NULL,
    activo      BIT(1)       NOT NULL,
    descripcion VARCHAR(255),
    nombre      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_categoria_nombre UNIQUE (nombre)
);

-- Catálogo de artículos. El tipo decide el comportamiento (POS, recetas);
-- la categoría es solo una etiqueta.
CREATE TABLE esp_productos (
    id                  BIGINT        NOT NULL AUTO_INCREMENT,
    created_at          DATETIME(6)   NOT NULL,
    updated_at          DATETIME(6)   NOT NULL,
    activo              BIT(1)        NOT NULL,
    codigo              VARCHAR(50)   NOT NULL,
    nombre              VARCHAR(100)  NOT NULL,
    tipo                ENUM('ELABORADO','REVENTA','MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA','PAQUETE') NOT NULL,
    -- false = preparación base: un ELABORADO que nunca se vende (ej. ganache).
    vendible            BIT(1)        NOT NULL DEFAULT 1,
    version             BIGINT        NOT NULL DEFAULT 0,
    porcentaje_ganancia DECIMAL(10,2),
    precio_costo        DECIMAL(10,2),
    precio_unitario     DECIMAL(10,2) NOT NULL,
    unidad_medida       ENUM('CAJA','GRAMO','KILO','LITRO','METRO','UNIDAD'),
    categoria_id        BIGINT,
    PRIMARY KEY (id),
    CONSTRAINT uk_esp_producto_codigo UNIQUE (codigo),
    CONSTRAINT fk_esp_producto_categoria FOREIGN KEY (categoria_id) REFERENCES categorias (id),
    CONSTRAINT ck_preparacion_base CHECK (vendible = 1 OR tipo = 'ELABORADO')
);

CREATE TABLE articulos_stock (
    id              BIGINT      NOT NULL AUTO_INCREMENT,
    created_at      DATETIME(6) NOT NULL,
    updated_at      DATETIME(6) NOT NULL,
    cantidad        INT         NOT NULL,
    stock_minimo    INT,
    version         BIGINT      NOT NULL DEFAULT 0,
    esp_producto_id BIGINT      NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_articulo_stock_producto UNIQUE (esp_producto_id),
    CONSTRAINT fk_articulo_stock_esp_producto FOREIGN KEY (esp_producto_id) REFERENCES esp_productos (id)
);

-- Materias primas e insumos. Pasan a esp_productos en la etapa 3.
CREATE TABLE materias_primas (
    id              BIGINT        NOT NULL AUTO_INCREMENT,
    created_at      DATETIME(6)   NOT NULL,
    updated_at      DATETIME(6)   NOT NULL,
    activo          BIT(1)        NOT NULL,
    codigo          VARCHAR(50)   NOT NULL,
    -- Elegido en el alta; define el prefijo del código (MP-, INS-, RMP-).
    tipo            ENUM('MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA') NOT NULL DEFAULT 'MATERIA_PRIMA',
    costo_unitario  DECIMAL(10,2) NOT NULL,
    nombre          VARCHAR(100)  NOT NULL,
    stock_actual    INT           NOT NULL,
    stock_minimo    INT           NOT NULL,
    unidad_medida   ENUM('CAJA','GRAMO','KILO','LITRO','METRO','UNIDAD') NOT NULL,
    esp_producto_id BIGINT,
    PRIMARY KEY (id),
    CONSTRAINT uk_materia_prima_codigo UNIQUE (codigo),
    CONSTRAINT fk_materia_prima_esp_producto FOREIGN KEY (esp_producto_id) REFERENCES esp_productos (id)
);

-- Códigos generados por el sistema: último número usado por prefijo.
-- El alta bloquea la fila (SELECT ... FOR UPDATE) hasta el commit.
CREATE TABLE secuencias_codigo (
    prefijo VARCHAR(10) NOT NULL,
    ultimo  INT         NOT NULL,
    PRIMARY KEY (prefijo)
);

INSERT INTO secuencias_codigo (prefijo, ultimo) VALUES
('ELA', 0), ('REV', 0), ('MP', 0), ('INS', 0), ('RMP', 0), ('PAQ', 0);

CREATE TABLE recetas (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    created_at         DATETIME(6)   NOT NULL,
    updated_at         DATETIME(6)   NOT NULL,
    activo             BIT(1)        NOT NULL,
    costos_adicionales DECIMAL(10,2),
    descripcion        VARCHAR(255),
    nombre             VARCHAR(100)  NOT NULL,
    esp_producto_id    BIGINT        NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_receta_producto UNIQUE (esp_producto_id),
    CONSTRAINT fk_receta_esp_producto FOREIGN KEY (esp_producto_id) REFERENCES esp_productos (id)
);

CREATE TABLE recetas_detalles (
    id               BIGINT        NOT NULL AUTO_INCREMENT,
    created_at       DATETIME(6)   NOT NULL,
    updated_at       DATETIME(6)   NOT NULL,
    cantidad         DECIMAL(10,3) NOT NULL,
    unidad_medida    ENUM('CAJA','GRAMO','KILO','LITRO','METRO','UNIDAD') NOT NULL,
    materia_prima_id BIGINT        NOT NULL,
    receta_id        BIGINT        NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_receta_detalle_materia_prima FOREIGN KEY (materia_prima_id) REFERENCES materias_primas (id),
    CONSTRAINT fk_receta_detalle_receta FOREIGN KEY (receta_id) REFERENCES recetas (id)
);

CREATE TABLE ventas (
    id                 BIGINT        NOT NULL AUTO_INCREMENT,
    created_at         DATETIME(6)   NOT NULL,
    updated_at         DATETIME(6)   NOT NULL,
    creado_por_usuario INT,
    fecha_hora         DATETIME(6)   NOT NULL,
    id_sesion_caja     INT,
    total              DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id)
);

-- Un producto con ventas no se puede borrar (no se elimina nada: solo baja lógica).
CREATE TABLE lineas_venta (
    id              BIGINT        NOT NULL AUTO_INCREMENT,
    created_at      DATETIME(6)   NOT NULL,
    updated_at      DATETIME(6)   NOT NULL,
    cantidad        INT           NOT NULL,
    costo_unitario  DECIMAL(10,2),
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    codigo_producto BIGINT        NOT NULL,
    id_venta        BIGINT        NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_linea_venta_producto FOREIGN KEY (codigo_producto) REFERENCES esp_productos (id) ON DELETE RESTRICT,
    CONSTRAINT fk_linea_venta_venta FOREIGN KEY (id_venta) REFERENCES ventas (id)
);

CREATE TABLE pagos_venta (
    id         BIGINT        NOT NULL AUTO_INCREMENT,
    created_at DATETIME(6)   NOT NULL,
    updated_at DATETIME(6)   NOT NULL,
    metodo     VARCHAR(30)   NOT NULL,
    monto      DECIMAL(10,2) NOT NULL,
    venta_id   BIGINT        NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_pago_venta FOREIGN KEY (venta_id) REFERENCES ventas (id)
);

CREATE TABLE movimientos_financieros (
    id          BIGINT        NOT NULL AUTO_INCREMENT,
    created_at  DATETIME(6)   NOT NULL,
    updated_at  DATETIME(6)   NOT NULL,
    categoria   VARCHAR(50),
    descripcion VARCHAR(255),
    fecha_hora  DATETIME(6)   NOT NULL,
    metodo_pago VARCHAR(30)   NOT NULL,
    monto       DECIMAL(10,2) NOT NULL,
    tipo        ENUM('EGRESO','INGRESO') NOT NULL,
    pago_id     BIGINT,
    PRIMARY KEY (id),
    CONSTRAINT fk_mov_financiero_pago FOREIGN KEY (pago_id) REFERENCES pagos_venta (id)
);

CREATE TABLE pedidos (
    id               BIGINT        NOT NULL AUTO_INCREMENT,
    created_at       DATETIME(6)   NOT NULL,
    updated_at       DATETIME(6)   NOT NULL,
    activo           BIT(1)        NOT NULL,
    cliente_nombre   VARCHAR(100)  NOT NULL,
    cliente_telefono VARCHAR(50)   NOT NULL,
    descripcion      VARCHAR(255)  NOT NULL,
    estado           ENUM('CANCELADO','PAGADO','PENDIENTE') NOT NULL,
    fecha_entrega    DATETIME(6),
    monto_total      DECIMAL(10,2) NOT NULL,
    saldo            DECIMAL(10,2) NOT NULL,
    senia            DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE pedidos_abonos (
    id          BIGINT        NOT NULL AUTO_INCREMENT,
    created_at  DATETIME(6)   NOT NULL,
    updated_at  DATETIME(6)   NOT NULL,
    metodo_pago VARCHAR(50),
    monto       DECIMAL(10,2) NOT NULL,
    nota        VARCHAR(255),
    pedido_id   BIGINT        NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_pedido_abono_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos (id)
);

CREATE TABLE configuracion_negocio (
    id             BIGINT       NOT NULL AUTO_INCREMENT,
    created_at     DATETIME(6)  NOT NULL,
    updated_at     DATETIME(6)  NOT NULL,
    codigo_cliente VARCHAR(50),
    descripcion    VARCHAR(255),
    direccion      VARCHAR(200),
    logo           LONGBLOB,
    nombre         VARCHAR(100) NOT NULL,
    telefono       VARCHAR(50),
    PRIMARY KEY (id)
);

CREATE TABLE esp_usuarios (
    id       BIGINT       NOT NULL AUTO_INCREMENT,
    activo   BIT(1)       NOT NULL,
    password VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_usuario_username UNIQUE (username)
);
