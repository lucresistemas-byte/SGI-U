# Resumen de bugs detectados en la verificación del backend SGI-U

Fecha: 2026-09-21
Entorno: backend en `http://localhost:3000`, MaríaDB 10.11, Java 21, Spring Boot 3.5.13.
Verificación: suite automatizada (`./mvnw test`, 115/115 OK) + 73 asserts manuales vía API (70 PASS / 3 FAIL).

Los **3 fallos** detectados corresponden a bugs reales: entradas de usuario inválidas responden **HTTP 500** en lugar de **400**.

---

## 1. VENT-04 — Cantidad `0` en línea de venta responde 500 (debería ser 400)

- **Request:** `POST /api/ventas` con `{"metodoPago":1,"lineas":[{"codigoProducto":"PROD-001","cantidad":0}]}`
- **Respuesta actual:** `500 Error interno del servidor`
- **Esperado:** `400` con mensaje de validación.
- **Causa raíz:** `VentaRequestDTO.lineas` no declara `@Valid` en cascada, por lo que la anotación `@Positive(message = "La cantidad debe ser mayor a cero")` de `LineaVentaDTO.java:7` nunca se ejecuta. La validación no dispara `MethodArgumentNotValidException`; el servicio lanza una excepción que cae en el bloque `catch (Exception e)` de `VentaController.java:31` y se responde como error interno.
- **Fix sugerido:** agregar `@Valid` a `List<LineaVentaDTO> lineas` en `VentaRequestDTO` (y opcionalmente `@NotEmpty`).

---

## 2. CAT-04 — Crear categoría sin nombre responde 500 (debería ser 400)

- **Request:** `POST /api/categorias` con `{"nombre":"","descripcion":"x"}`
- **Respuesta actual:** `500 {"codigo":"ERROR_DASHBOARD","error":true,"mensaje":"No se pudo generar el Dashboard"}`
- **Esperado:** `400` con mensaje indicando que el nombre es obligatorio.
- **Causa raíz:** `CategoriaController.crearCategoria` no aplica `@Valid` sobre el DTO ni captura la `IllegalArgumentException("El nombre de la categoría es obligatorio.")` lanzada por `CategoriaService`. La excepción escapa y es resuelta por `GlobalExceptionHandler.handleGeneral` (`GlobalExceptionHandler.java:94`) → 500.
- **Fix sugerido:** agregar `@Valid` al `@RequestBody CategoriaDTO` (con `@NotBlank` en `nombre`) y/o manejar `IllegalArgumentException` devolviendo 400.

---

## 3. BAL-04 — Balance sin parámetros responde 500 (debería ser 400)

- **Request:** `GET /api/balance` (faltan `fechaInicio` y `fechaFin`)
- **Respuesta actual:** `500 {"codigo":"ERROR_DASHBOARD","error":true,"mensaje":"No se pudo generar el Dashboard"}`
- **Esperado:** `400` indicando parámetros obligatorios.
- **Causa raíz:** Spring lanza `MissingServletRequestParameterException`, que NO tiene `@ExceptionHandler` específico en `GlobalExceptionHandler`, por lo que cae en `handleGeneral` → 500.
- **Fix sugerido:** agregar `@ExceptionHandler(MissingServletRequestParameterException.class)` que responda 400 con `{"error": true, "codigo":"PARAMETRO_REQUERIDO", "mensaje": "..."}`.

---

## Patrón común

Los 3 bugs atraviesan `handleGeneral` (`GlobalExceptionHandler.java:94`), que devuelve **500** con un mensaje genérico y engañoso (`codigo: ERROR_DASHBOARD`, `"No se pudo generar el Dashboard"`) sin relación con el recurso afectado.

Impacto:
- Errores de validación del cliente se reportan como fallas de servidor.
- El mensaje "Dashboard" confunde el diagnóstico en logs y en el cliente.
- Daña la semántica HTTP y la observabilidad.

**Recomendación:** revisar el manejo global de excepciones para que toda excepción de validación/parámetro/estado inválido responda 4xx con un mensaje real del error, dejando 500 solo para fallos internos genuinos.

---

## Resolución (verificada el 2026-09-21)

Los 3 bugs fueron corregidos y re-verificados contra el backend relanzado en `:3000`:

| Bug | Antes | Después | Verificación |
|---|---|---|---|
| VENT-04 cantidad 0 | 500 | `400 {"error":"La cantidad debe ser mayor a cero"}` | PASS |
| VENT-04 sin líneas | — | `400 {"error":"La venta debe tener al menos una línea."}` | PASS |
| CAT-04 sin nombre | 500 | `400 {"error":"El nombre de la categoría es obligatorio."}` | PASS |
| BAL-04 sin parámetros | 500 | `400 {"codigo":"PARAMETRO_REQUERIDO","mensaje":"Parámetro requerido no provisto: fechaInicio"}` | PASS |

**Cambios aplicados:**
1. `models/dtos/VentaRequestDTO.java` — se agregó `@Valid @NotEmpty` sobre `lineas` para activar la validación en cascada (`@Positive` de `LineaVentaDTO`).
2. `models/dtos/CategoriaDTO.java` — se agregó `@NotBlank(message="El nombre de la categoría es obligatorio.")` en `nombre`.
3. `controllers/CategoriaController.java` — se agregó `@Valid` al `@RequestBody`.
4. `exceptions/GlobalExceptionHandler.java` — se agregaron handlers para `MissingServletRequestParameterException` (→ 400 `PARAMETRO_REQUERIDO`) y `IllegalArgumentException` (→ 400 con el mensaje real), evitando que caigan en `handleGeneral` con el mensaje falso de "Dashboard".

**Resultado final de la verificación completa:**
- Suite automatizada: **115/115 tests OK** (0 fallos, 0 errores).
- Verificación manual de la API: **73 PASS / 0 FAIL** (63 casos de la guía, incluidos los 3 reprobados en la primera pasada).

## Referencias de código

| Bug | Archivo | Línea |
|---|---|---|
| VENT-04 | `models/dtos/VentaRequestDTO.java` | `lineas` sin `@Valid` |
| VENT-04 | `controllers/VentaController.java` | 31 (catch genérico → 500) |
| CAT-04 | `controllers/CategoriaController.java` | 26 (sin `@Valid` ni manejo de error) |
| BAL-04 | `exceptions/GlobalExceptionHandler.java` | falta handler de `MissingServletRequestParameterException` |
| Común | `exceptions/GlobalExceptionHandler.java` | 94 (`handleGeneral` con mensaje "Dashboard") |

---

## Estado del resto de la verificación

- Suite automatizada: **115/115 tests OK** (0 fallos, 0 errores).
- Verificación manual (post-fix): **73 PASS / 0 FAIL** sobre los 63 casos de la guía.
- JaCoCo: `./mvnw verify` compila OK pero **no genera reporte**: el plugin `jacoco-maven-plugin` no está configurado en `pom.xml`.