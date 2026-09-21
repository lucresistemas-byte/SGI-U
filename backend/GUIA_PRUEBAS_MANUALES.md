# Guía de Pruebas Manuales — Backend SGI-U

Guía para arrancar el backend y ejecutar pruebas manuales de la API REST con **Insomnia**.

- **Base URL local:** `http://localhost:3000`
- **Stack:** Spring Boot 3.5.13 / Java 21 · MariaDB 10.11 (Docker)
- **Autenticación:** JWT (Bearer). Solo `/api/auth/**` es público; el resto exige `Authorization: Bearer <token>`.
- **Usuario seed:** `admin` / `admin123`

---

## 1. Cómo arrancar el backend

### 1.1 Requisitos
- Docker (para MariaDB) o MariaDB corriendo en `localhost:3306`.
- JDK 21 y Maven (`./mvnw` incluido).
- El proyecto está en `SGI-U/backend/sgiu/`.

### 1.2 Levantar la base de datos (Docker)
```bash
cd SGI-U/backend
docker compose up -d
```
- Crea y levanta el contenedor `sgiu-mariadb` (MariaDB 10.11) mapeado al puerto `3306`.
- Credenciales definidas en `docker-compose.yml` (y `.env`):
  - Base de datos: `sgiu_db`
  - Usuario / password: `sgiu_user` / `sgiu_1234`
  - Root: `Lucio1234`

Verificá que esté healthy:
```bash
docker compose ps
```

### 1.3 Levantar el backend (Maven)
```bash
cd SGI-U/backend/sgiu
./mvnw clean spring-boot:run
```
- `application.yml` conecta a `jdbc:mariadb://localhost:3306/sgiu_db` con `sgiu_user`/`sgiu_1234`.
- El servidor escucha en `0.0.0.0:3000` (el `Launcher` fuerza `server.port=3000`).
- Al iniciar ejecuta `data.sql` (inserts de categorías, productos, stock, usuarios, ventas demo, insumos, recetas y pedidos) y un `DataSeeder` que crea `admin` si no existe.

### 1.4 Verificar el arranque
> [!NOTE]
> **No existe `/actuator/health`** (no está la dependencia de Actuator en el `pom.xml`; el README está desactualizado). Usá estos checks reales:

```bash
# 1) Login (público) → devuelve token JWT
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 2) Endpoint protegido sin token → debe devolver 401
curl -s http://localhost:3000/api/productos
```

---

## 2. Datos de prueba (seed)

| Código | Nombre | Precio venta | Precio costo | Unidad | Categoría | Stock |
|---|---|---|---|---|---|---|
| PROD-001 | Arroz Integral 1kg | 100.00 | 70.00 | KILO | Alimentos | 50 |
| PROD-002 | Leche Entera 1L | 250.50 | 180.00 | LITRO | Alimentos | 30 |
| PROD-003 | Cerveza Brahma | 75.25 | 50.00 | UNIDAD | Bebidas | 100 |
| PROD-004 | Carbón Vegetal 5kg | 320.00 | 220.00 | UNIDAD | Alimentos | 3 (*crítico*) |
| PROD-005 | Coca-Cola | 150.75 | 100.00 | UNIDAD | Bebidas | **0** (*sin stock*) |

- **Categorías:** `1` Alimentos · `2` Bebidas
- **Insumos:** `MP-001` Arroz Crudo ($35.00/KILO, stock 500) · `MP-002` Bolsa Biodegradable ($5.00/UNIDAD, stock 1000) · `MP-003` Etiqueta Sandra ($2.50/UNIDAD, stock 2000)
- **Receta:** ID `1` → producto `PROD-001` (consumo de MP-001, MP-002 y MP-003, +$5 costos adicionales)
- **Pedidos:** ID `1` Carlos Pérez → PENDIENTE, saldo $700 · ID `2` Laura Gómez → PAGADO
- **Ventas demo (junio 2026):** IDs 100–104 · **Movimientos financieros demo:** IDs 100–107

**Enums útiles:** `UnidadMedida` = GRAMO, KILO, UNIDAD, CAJA, METRO, LITRO · `TipoMovimiento` = INGRESO, EGRESO · `EstadoPedido` = PENDIENTE, PAGADO, CANCELADO.

---

## 3. Setup en Insomnia

### 3.1 Crear el environment
1. Creá una **Collection** nueva: `SGI-U Backend`.
2. En la pestaña **Environments** (rueda del panel izquierdo) creá un environment tipo **Local** con:
   ```json
   {
     "base_url": "http://localhost:3000",
     "token": ""
   }
   ```
3. Seleccioná ese environment (desplegable arriba). Todos los request usan `{{ base_url }}`.

### 3.2 Request de Login + token
Dentro de la colección creá una carpeta **Auth** con el request:

- **POST** `{{ base_url }}/api/auth/login`
- Headers: `Content-Type: application/json`
- Body (JSON):
  ```json
  {
    "username": "admin",
    "password": "admin123"
  }
  ```
- Respuesta esperada (200):
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "id": 1,
    "username": "admin",
    "activo": true
  }
  ```

**Configurar el token automáticamente (opcional pero recomendado):**
1. En el request *Login*, click derecho en el panel izquierdo → **Set from Response (Settings)** → elegí *Login* → variable de entorno `token` → `Body > JSONPath` con path `token`. Guardá.
2. Usá **Environment** → gestioná `token` para pegar el valor manualmente (algunas versiones requieren refrescar).

Con el token cargado, configurá **Auth > Bearer** en cada request del resto de carpetas con valor `{{ token }}`. Alternativa: header `Authorization: Bearer {{ token }}`.

> Los endpoints protegidos **sin** `{{ token }}` devuelven: `401` con body `{"error":"No autorizado"}`.

### 3.3 Estructura de carpetas sugerida
```
SGI-U Backend
├── Auth
├── Categorías
├── Productos
├── Ventas
├── Insumos
├── Recetas
├── Pedidos
├── Movimientos
├── Balance
├── Dashboard
├── Configuración
└── Backups
```

> Existe además **`insomnia-collection.json`** en esta misma carpeta: importalo con `Ctrl/Cmd+I` → *Insomnia 4 / Kong Insomnia* para tener toda la colección preconfigurada con `{{ token }}`.

---

## 4. Guía de pruebas por módulo

> Para cada caso con body se muestra el JSON exacto. **Resultado esperado** = código HTTP y forma de la respuesta.

### 4.1 Autenticación (`/api/auth`)

Carpeta **Auth** · Envía `Content-Type: application/json`.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| A-01 Login correcto | `POST {{ base_url }}/api/auth/login` | `{"username":"admin","password":"admin123"}` | `200` con `token`, `id`, `username`, `activo` |
| A-02 Login contraseña incorrecta | `POST {{ base_url }}/api/auth/login` | `{"username":"admin","password":"mala"}` | `401` con `{"error":"Credenciales incorrectas"}` |
| A-03 Login usuario inexistente | `POST {{ base_url }}/api/auth/login` | `{"username":"pepe","password":"x"}` | `401` con `{"error":"Credenciales incorrectas"}` |
| A-04 Register nuevo usuario | `POST {{ base_url }}/api/auth/register` | `{"username":"test01","password":"clave123"}` | `200` con `token` y `activo: true` |
| A-05 Register usuario duplicado | `POST {{ base_url }}/api/auth/register` | `{"username":"test01","password":"otra"}` | `400` con `{"error":"El nombre de usuario ya está en uso"}` |

### 4.2 Categorías (`/api/categorias`)

Carpeta **Categorías** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| CAT-01 Listar categorías | `GET {{ base_url }}/api/categorias` | — | `200` array con las seeds (`Alimentos`, `Bebidas`) |
| CAT-02 Crear categoría | `POST {{ base_url }}/api/categorias` | `{"nombre":"Limpieza","descripcion":"Artículos de limpieza e higiene","activo":true}` | `201` con `{id, nombre, descripcion, activo}` |
| CAT-03 Crear categoría duplicada | `POST {{ base_url }}/api/categorias` | `{"nombre":"Alimentos","descripcion":"x"}` | `409` con `{"error":"Ya existe una categoría con el nombre: Alimentos"}` |
| CAT-04 Crear sin nombre | `POST {{ base_url }}/api/categorias` | `{"nombre":"","descripcion":"x"}` | `400` con `{"error":"El nombre de la categoría es obligatorio."}` |
| CAT-05 Sin token | `GET {{ base_url }}/api/categorias` (sin Bearer) | — | `401` con `{"error":"No autorizado"}` |

### 4.3 Productos (`/api/productos`)

Carpeta **Productos** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| PROD-01 Catálogo completo | `GET {{ base_url }}/api/productos` | — | `200` array de 5 productos con `codigo, nombre, precioUnitario, precioCosto, porcentajeGanancia, unidadMedida, categoria, stockActual, stockMinimo, activo` |
| PROD-02 Catálogo por categoría | `GET {{ base_url }}/api/productos?categoria=Alimentos` | — | `200` solo productos de Alimentos |
| PROD-03 Crear producto | `POST {{ base_url }}/api/productos/crear` | `{"codigo":"PROD-006","nombre":"Azúcar 1kg","precioUnitario":120.00,"precioCosto":80.00,"porcentajeGanancia":50.00,"unidadMedida":"KILO","categoriaId":1,"stockActual":40,"stockMinimo":5,"activo":true}` | `201` con el producto creado (precio/costo/margen coherentes) |
| PROD-04 Código duplicado | `POST {{ base_url }}/api/productos/crear` | `{"codigo":"PROD-001","nombre":"Otro","precioUnitario":1.00}` | `409` con `{"error":"El código de producto ya existe."}` |
| PROD-05 Precio cero o negativo | `POST {{ base_url }}/api/productos/crear` | `{"codigo":"PROD-007","nombre":"X","precioUnitario":0}` | `422` con error de validación |
| PROD-06 Unidad inválida | `POST {{ base_url }}/api/productos/crear` | `{"codigo":"PROD-008","nombre":"Y","precioUnitario":10,"unidadMedida":"KILAZO"}` | `422` con `{"error":"Unidad de medida no válida: KILAZO"}` |
| PROD-07 Editar producto | `PUT {{ base_url }}/api/productos/editar/PROD-006` | `{"nombre":"Azúcar Blanca 1kg","precioUnitario":130.00}` | `200` con datos actualizados |
| PROD-08 Editar inexistente | `PUT {{ base_url }}/api/productos/editar/PROD-999` | `{"nombre":"X"}` | `404` con `{"error":"No se encontró un producto con el código: PROD-999"}` |
| PROD-09 Ajustar stock (+) | `PUT {{ base_url }}/api/productos/stock/PROD-006` | `{"cantidad":10,"motivo":"Compra a proveedor"}` | `200` con `stockActual: 50` |
| PROD-10 Ajustar stock (−) | `PUT {{ base_url }}/api/productos/stock/PROD-004` | `{"cantidad":-2,"motivo":"Merma"}` | `200` con `stockActual: 1` |
| PROD-11 Stock negativo | `PUT {{ base_url }}/api/productos/stock/PROD-004` | `{"cantidad":-50,"motivo":"Error"}` | `422` con `{"error":"El stock no puede quedar negativo."}` |
| PROD-12 Sin motivo | `PUT {{ base_url }}/api/productos/stock/PROD-001` | `{"cantidad":5}` | `400` con `{"error":"El motivo es obligatorio."}` |

### 4.4 Ventas (`/api/ventas`)

Carpeta **Ventas** · **Auth Bearer requerido**.

> [!IMPORTANT]
> En `POST /api/ventas` el campo `metodoPago` es **numérico (Long)** en el DTO. El README muestra `"EFECTIVO"` (string) que **falla con 400**. Enviar un número (ej. `1`); el backend lo guarda como método del pago. Los precios **no** se envían: el backend los toma de la BD (RN05).

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| VENT-01 Venta feliz | `POST {{ base_url }}/api/ventas` | `{"metodoPago":1,"lineas":[{"codigoProducto":"PROD-001","cantidad":2},{"codigoProducto":"PROD-003","cantidad":3}]}` | `201` (body vacío). Se descuenta stock, se crean `venta`, `lineas_venta`, `pago_venta` y `movimiento_financiero` (INGRESO) |
| VENT-02 Stock insuficiente (rollback) | `POST {{ base_url }}/api/ventas` | `{"metodoPago":1,"lineas":[{"codigoProducto":"PROD-005","cantidad":1}]}` (PROD-005 tiene stock 0) | `400` con texto `Stock insuficiente para: PROD-005`. Verificá que **nada** se persistió (rollback atómico) |
| VENT-03 Producto inexistente | `POST {{ base_url }}/api/ventas` | `{"metodoPago":1,"lineas":[{"codigoProducto":"PROD-999","cantidad":1}]}` | `404` con texto `Producto no encontrado: PROD-999` |
| VENT-04 Cantidad inválida | `POST {{ base_url }}/api/ventas` | `{"metodoPago":1,"lineas":[{"codigoProducto":"PROD-001","cantidad":0}]}` | `400` (validación: cantidad > 0) |
| VENT-05 `metodoPago` como string | `POST {{ base_url }}/api/ventas` | `{"metodoPago":"EFECTIVO","lineas":[{"codigoProducto":"PROD-001","cantidad":1}]}` | `400` con `{"error":"Error en el formato de los datos o valor inválido."}` (Jackson no puede convertir string→Long) |
| VENT-06 Venta con receta (descuenta insumos) | `POST {{ base_url }}/api/ventas` | `{"metodoPago":1,"lineas":[{"codigoProducto":"PROD-001","cantidad":5}]}` | `201`. Verificá que bajó el stock de MP-001 (500→495), MP-002 y MP-003 |

**Verificación post venta (recomendado):** `GET {{ base_url }}/api/productos` para confirmar stock descontado y `GET {{ base_url }}/api/movimientos` para ver el INGRESO generado con total = Σ(precio_unitario × cantidad).

### 4.5 Insumos (`/api/insumos`)

Carpeta **Insumos** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| INS-01 Listar insumos | `GET {{ base_url }}/api/insumos` | — | `200` con MP-001, MP-002 y MP-003 |
| INS-02 Obtener por id | `GET {{ base_url }}/api/insumos/1` | — | `200` con el insumo MP-001 |
| INS-03 Id inexistente | `GET {{ base_url }}/api/insumos/999` | — | `404` con `{"error":"Insumo no encontrado con ID: 999"}` |
| INS-04 Crear insumo | `POST {{ base_url }}/api/insumos` | `{"codigo":"MP-004","nombre":"Harina 0000","costoUnitario":45.00,"unidadMedida":"KILO","stockActual":300,"stockMinimo":30}` | `201` con el insumo creado |
| INS-05 Código duplicado | `POST {{ base_url }}/api/insumos` | `{"codigo":"MP-001","nombre":"Otro","costoUnitario":1.00}` | `400` con `{"error":"Ya existe un insumo con el código: MP-001"}` |
| INS-06 Editar insumo | `PUT {{ base_url }}/api/insumos/1` | `{"codigo":"MP-001","nombre":"Arroz Crudo Premium","costoUnitario":38.00,"unidadMedida":"KILO"}` | `200`; si cambió el costo, recalcula la receta 1 y el costo/precio de PROD-001 |
| INS-07 Ajustar stock (+) | `POST {{ base_url }}/api/insumos/1/ajuste-stock` | `{"cantidad":50,"motivo":"Reposición"}` | `200` con stock incrementado |
| INS-08 Ajuste que deja en negativo | `POST {{ base_url }}/api/insumos/2/ajuste-stock` | `{"cantidad":-5000,"motivo":"Error"}` | `400` con `{"error":"El stock resultante no puede ser negativo..."}` |
| INS-09 Ajuste sin motivo | `POST {{ base_url }}/api/insumos/1/ajuste-stock` | `{"cantidad":10}` | `400` con `{"error":"El motivo del ajuste es obligatorio"}` |

### 4.6 Recetas (`/api/recetas`)

Carpeta **Recetas** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| REC-01 Listar recetas | `GET {{ base_url }}/api/recetas` | — | `200` con la receta 1 |
| REC-02 Por id | `GET {{ base_url }}/api/recetas/1` | — | `200` con `costoTotal` calculado y `detalles` |
| REC-03 Por código producto | `GET {{ base_url }}/api/recetas/producto/PROD-001` | — | `200` con la receta del elaborado |
| REC-04 Crear receta | `POST {{ base_url }}/api/recetas` | `{"espProductoCodigo":"PROD-002","nombre":"Receta Leche Envasada","descripcion":"Reempaque 1L","costosAdicionales":10.00,"detalles":[{"materiaPrimaId":1,"cantidad":1.000,"unidadMedida":"LITRO"},{"materiaPrimaId":2,"cantidad":1.000,"unidadMedida":"UNIDAD"}]}` | `201` con receta y `costoTotal` |
| REC-05 Receta sin detalles | `POST {{ base_url }}/api/recetas` | `{"espProductoCodigo":"PROD-003","nombre":"Sin insumos","detalles":[]}` | `400` con `{"error":"La receta debe contener al menos un insumo"}` |
| REC-06 Editar receta | `PUT {{ base_url }}/api/recetas/1` | `{"espProductoCodigo":"PROD-001","nombre":"Receta Fraccionado Arroz v2","descripcion":"Actualizada","costosAdicionales":6.00,"detalles":[{"materiaPrimaId":1,"cantidad":1.000,"unidadMedida":"KILO"},{"materiaPrimaId":2,"cantidad":1.000,"unidadMedida":"UNIDAD"},{"materiaPrimaId":3,"cantidad":1.000,"unidadMedida":"UNIDAD"}]}` | `200` |
| REC-07 Eliminar receta | `DELETE {{ base_url }}/api/recetas/2` (la creada en REC-04) | — | `204` sin body |

### 4.7 Pedidos (`/api/pedidos`)

Carpeta **Pedidos** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| PED-01 Listar pedidos | `GET {{ base_url }}/api/pedidos` | — | `200` con los 2 seeds (`estado`, `senia`, `saldo`, `abonos`) |
| PED-02 Buscar por nombre/teléfono | `GET {{ base_url }}/api/pedidos?q=Carlos` | — | `200` solo pedidos de Carlos Pérez |
| PED-03 Obtener por id | `GET {{ base_url }}/api/pedidos/1` | — | `200` con pedido y abonos |
| PED-04 Crear pedido con seña | `POST {{ base_url }}/api/pedidos` | `{"clienteNombre":"María López","clienteTelefono":"343-5559988","descripcion":"Pedido para cumpleaños","montoTotal":2000.00,"senia":500.00,"fechaEntrega":"2026-07-10T18:00:00","metodoPagoSenia":"EFECTIVO"}` | `201` con `saldo: 1500`, `estado: PENDIENTE`, 1 abono |
| PED-05 Seña mayor al total | `POST {{ base_url }}/api/pedidos` | `{"clienteNombre":"X","clienteTelefono":"343-5550000","descripcion":"Y","montoTotal":1000.00,"senia":1500.00}` | `400` con `{"error":"La seña no puede ser mayor al monto total del pedido"}` |
| PED-06 Abonar saldo | `POST {{ base_url }}/api/pedidos/1/abonar` | `{"monto":700.00,"metodoPago":"TRANSFERENCIA","nota":"Saldo total"}` | `200` con `saldo: 0`, `estado: PAGADO`, 2 abonos |
| PED-07 Abonar de más | `POST {{ base_url }}/api/pedidos/2/abonar` (ya PAGADO) | `{"monto":100.00}` | `400` con `{"error":"No se pueden registrar abonos a un pedido en estado PAGADO"}` |
| PED-08 Cancelar pedido | `POST {{ base_url }}/api/pedidos/4/cancelar` (ID del pedido creado en PED-04) | — | `200` con `estado: CANCELADO` |
| PED-09 Cancelar pedido pagado | `POST {{ base_url }}/api/pedidos/2/cancelar` | — | `400` con `{"error":"No se puede cancelar un pedido que ya ha sido completamente pagado"}` |
| PED-10 Id inexistente | `GET {{ base_url }}/api/pedidos/999` | — | `404` con `{"error":"Pedido no encontrado con ID: 999"}` |

### 4.8 Movimientos financieros (`/api/movimientos`)

Carpeta **Movimientos** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| MOV-01 Crear EGRESO | `POST {{ base_url }}/api/movimientos` | `{"tipo":"EGRESO","monto":2500.00,"metodoPago":"EFECTIVO","categoria":"PROVEEDOR","descripcion":"Compra de mercadería","fechaHora":"2026-09-20T10:00:00"}` | `201` con el movimiento creado (`tipo`, `monto`, `costo`, `ganancia`) |
| MOV-02 Crear INGRESO | `POST {{ base_url }}/api/movimientos` | `{"tipo":"INGRESO","monto":1200.00,"metodoPago":"MERCADO_PAGO","categoria":"VENTA","descripcion":"Pago recibido"}` | `201` |
| MOV-03 Tipo inválido | `POST {{ base_url }}/api/movimientos` | `{"tipo":"GARBAGE","monto":100.00,"metodoPago":"EFECTIVO"}` | `400` con `{"error":"El tipo de movimiento debe ser INGRESO o EGRESO."}` |
| MOV-04 Monto negativo o cero | `POST {{ base_url }}/api/movimientos` | `{"tipo":"EGRESO","monto":0,"metodoPago":"EFECTIVO"}` | `400` (validación: monto > 0) |
| MOV-05 Listar movimientos | `GET {{ base_url }}/api/movimientos` | — | `200` ordenado por fecha desc (seeds 100–107 + los creados) |

### 4.9 Balance (`/api/balance`)

Carpeta **Balance** · **Auth Bearer requerido**.

| Caso | Método y URL | Resultado esperado |
|---|---|---|
| BAL-01 Balance del mes (datos demo) | `GET {{ base_url }}/api/balance?fechaInicio=2026-06-01&fechaFin=2026-06-30` | `200` con `totalIngresos`, `totalEgresos`, `margenNeto`, `costoTotal`, `gananciaReal`, `movimientos` |
| BAL-02 Fechas invertidas | `GET {{ base_url }}/api/balance?fechaInicio=2026-06-30&fechaFin=2026-06-01` | `400` con `{"error":"La fecha de inicio no puede ser posterior a la fecha de fin."}` |
| BAL-03 Fecha mal formateada | `GET {{ base_url }}/api/balance?fechaInicio=30-06-2026&fechaFin=2026-06-30` | `400` con `{"error":"Formato de fecha inválido. Use el formato ISO: yyyy-MM-dd."}` |
| BAL-04 Sin parámetros | `GET {{ base_url }}/api/balance` | `400` (faltan `fechaInicio`/`fechaFin`) |

### 4.10 Dashboard (`/api/dashboard`)

Carpeta **Dashboard** · **Auth Bearer requerido**.

| Caso | Método y URL | Resultado esperado |
|---|---|---|
| DASH-01 Dashboard completo | `GET {{ base_url }}/api/dashboard?fechaDesde=2026-06-01&fechaHasta=2026-06-30` | `200` con `filtrosAplicados`, `kpis`, `graficos`, `metadata` |
| DASH-02 Filtro por método de pago | `GET {{ base_url }}/api/dashboard?fechaDesde=2026-06-01&fechaHasta=2026-06-30&metodoPago=EFECTIVO` | `200` (valores: EFECTIVO, TRANSFERENCIA, MERCADO_PAGO, TARJETA) |
| DASH-03 Filtro por producto | `GET {{ base_url }}/api/dashboard?fechaDesde=2026-06-01&fechaHasta=2026-06-30&productoId=1` | `200` |
| DASH-04 Filtro por tipo | `GET {{ base_url }}/api/dashboard?fechaDesde=2026-06-01&fechaHasta=2026-06-30&tipoTransaccion=INGRESO` | `200` |
| DASH-05 Fechas inválidas | `GET {{ base_url }}/api/dashboard?fechaDesde=2026-06-30&fechaHasta=2026-06-01` | `400` con `{"error":true,"codigo":"FECHAS_INVALIDAS",...}` |

### 4.11 Configuración del negocio (`/api/configuracion`)

Carpeta **Configuración** · **Auth Bearer requerido**.

| Caso | Método y URL | Body | Resultado esperado |
|---|---|---|---|
| CONF-01 Obtener configuración | `GET {{ base_url }}/api/configuracion` | — | `200` con `SGI-U Almacén de Sandra`, `SGIU-SANDRA-001`, dirección, teléfono, descripción |
| CONF-02 Actualizar configuración | `PUT {{ base_url }}/api/configuracion` | `{"nombre":"Almacén de Sandra SA","codigoCliente":"SGIU-SANDRA-001","direccion":"Av. San Martín 1234","telefono":"343-5551234","descripcion":"Comercio minorista y punto de venta"}` | `200` con datos actualizados. No enviar `logo` respeta el existente |
| CONF-03 Actualización parcial | `PUT {{ base_url }}/api/configuracion` | `{"telefono":"343-5550000"}` | `200` — solo cambia el teléfono, resto intacto |

### 4.12 Backups (`/api/backups`)

Carpeta **Backups** · **Auth Bearer requerido**.

| Caso | Método y URL | Resultado esperado |
|---|---|---|
| BCK-01 Listar backups | `GET {{ base_url }}/api/backups` | `200` con `codigoCliente`, `b2Configurado` (probablemente `false` sin credenciales) y `archivos` |
| BCK-02 Ejecutar backup manual | `POST {{ base_url }}/api/backups/ejecutar` | `200` con `{"status":"success","mensaje":"Backup generado y procesado exitosamente","ubicacion":...,"timestamp":...}` o `500` con error si falla el dump |

---

## 5. Checklist de aceptación

Marcá cada caso al ejecutarlo:

**Auth**
- [ ] A-01 login correcto devuelve token · A-02/A-03 devuelven 401
- [ ] A-04 registro crea usuario · A-05 duplicado devuelve 400

**Categorías**
- [ ] CAT-01 lista · CAT-02 crea · CAT-03 409 duplicada · CAT-05 401 sin token

**Productos**
- [ ] PROD-01/02 catálogo (con/sin filtro) · PROD-03 crea · PROD-04 409 · PROD-07/08 edición · PROD-09/10/11/12 ajuste de stock (incl. negativo)

**Ventas (motor transaccional)**
- [ ] VENT-01 venta feliz 201 y descuenta stock
- [ ] VENT-02 stock insuficiente 400 **sin** dejar datos parciales (rollback)
- [ ] VENT-03 404 producto inexistente · VENT-05 400 con `metodoPago` string
- [ ] VENT-06 venta de elaborado descuenta insumos de la receta

**Insumos / Recetas**
- [ ] INS-01..09 (CRUD + ajuste stock) · REC-01..07 (CRUD recetas + costoTotal)

**Pedidos**
- [ ] PED-01/02/03 listado/búsqueda/detalle · PED-04 crea con seña
- [ ] PED-05 seña > total 400 · PED-06 abonar hasta quedar PAGADO · PED-09 cancelar pagado 400

**Finanzas / Reportes**
- [ ] MOV-01/02 crea movimientos · MOV-03 tipo inválido 400 · MOV-05 lista ordenada
- [ ] BAL-01 balance coherente · BAL-02/03 errores de fechas
- [ ] DASH-01 dashboard completo · DASH-02/03/04 filtros · DASH-05 fechas inválidas

**Configuración / Backups**
- [ ] CONF-01/02/03 obtener y actualizar (parcial y completa)
- [ ] BCK-01 lista backups · BCK-02 backup manual exitoso

**Seguridad transversal**
- [ ] Todo endpoint distinto de `/api/auth/**` devuelve `401` sin token
- [ ] Token inválido/expirado devuelve `401`

---

## 6. Notas y particularidades

1. **Puerto:** el backend corre en `3000`, no en `8080`. La referencia a `/actuator/health` en el README no aplica (no hay dependencia Actuator).
2. **`metodoPago` en ventas es numérico:** mandar un `Long` (ej. `1`). El string `"EFECTIVO"` produce `400` por fallo de deserialización Jackson.
3. **Actualizar stock de productos:** `PUT /stock/{codigo}` suma el valor indicado (positivo agrega, negativo descuenta) y exige `motivo`.
4. **Recetas ↔ precios:** editar el costo de un insumo (INS-06) recalcula automáticamente costo y precio del producto elaborado.
5. **Pedidos:** un abono nunca supera el saldo; al llegar a saldo 0 el pedido pasa a `PAGADO`; un pedido pagado no se puede cancelar.
6. **Fechas:** siempre en formato ISO `yyyy-MM-dd` (dashboard/balance) y `ISO date-time` para fechas de pedidos/movimientos.
7. **Restart limpio:** para volver al estado seed, recrear solo el volumen de la BD:
   ```bash
   docker compose down -v && docker compose up -d
   ```