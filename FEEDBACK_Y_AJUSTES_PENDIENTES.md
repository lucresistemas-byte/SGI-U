# 📋 Registro de Feedback, Mejoras y Ajustes Pendientes (SGI-U)

**Fecha de Relevamiento:** 22 de Septiembre de 2026  
**Origen:** Sesión de pruebas manuales (UAT) y revisión de requerimientos con Lucrecia  
**Destino:** Equipo de Desarrollo, Testing y Base de Datos (SGI-U)  
**Referencias Visuales:** Capturas incluidas en la carpeta `instrucciones/capturas con referencias/`

---

## 🎯 Resumen Ejecutivo y Categorización por Impacto

Para facilitar la planificación y distribución de tareas con el equipo, los 7 puntos relevados se han clasificado según su nivel de criticidad arquitectónica y su impacto en el modelo de datos:

| Nivel de Prioridad | Categoría | Puntos Incluidos | Impacto Principal |
| :--- | :--- | :--- | :--- |
| 🔴 **ALTA / ESTRUCTURAL** | **Arquitectura y Modelo de Datos** | **Punto 5:** Receta como Producto Elaborado integral<br>**Punto 6:** Creación y asignación de Categorías<br>**Punto 4:** Soft delete (Activar/Desactivar) en Materias Primas | Afecta esquema de Base de Datos, DTOs de Backend y servicios de integración. |
| 🟡 **MEDIA / FUNCIONAL** | **Lógica de Negocio y Flujo Operativo** | **Punto 3:** Unificación de edición de Insumos y análisis Stock Actual vs Mínimo<br>**Punto 1:** Rediseño del flujo de venta en POS y edición directa en carrito | Afecta BLoCs, controllers y experiencia del usuario en transacciones diarias. |
| 🟢 **SECUNDARIA / UX** | **Usabilidad y Refinamiento Visual** | **Punto 2:** Supresión del ticket PDF post-venta<br>**Punto 7:** Cierre de modales al hacer clic fuera (`barrierDismissible`) | Afecta componentes visuales de Flutter y navegación modal. |

---

## 🔴 NIVEL 1 — Aspectos Estructurales, Arquitectura y Base de Datos

---

### 📌 Punto 5: Recetas como Creación Directa de Producto Elaborado
*Replantear el formulario de recetas para que crear una receta dé de alta simultáneamente el Producto Elaborado y analice su impacto en BD.*

#### 1. Situación Actual y Problema
Actualmente, el flujo de recetas está desacoplado del catálogo:
1. El usuario debe ir primero a la pantalla **Productos** y crear un producto vacío (ej. "Torta Selva Negra").
2. Luego debe ir a **Recetas**, buscar ese producto en un desplegable y recién allí definirle los insumos.
Este flujo es contra-intuitivo para el negocio de pastelería/elaboración, genera duplicación de pasos y fricción operativa.

#### 2. Propuesta Funcional
- Unificar la creación: al ingresar a **Recetas → "Nueva Receta"**, el formulario debe entenderse directamente como el alta de un **Producto Elaborado**.
- En una sola pantalla se definen:
  - Nombre del producto elaborado (ej. "Torta Bombón 1kg").
  - Categoría (ej. "Pastelería", "Elaborados Propios").
  - Insumos necesarios con cantidades y unidades.
  - Costo total calculado automáticamente a partir de los insumos + costos fijos.
  - Margen deseado (%) y Precio de Venta final.
- Al guardar la receta, el producto queda inmediatamente disponible para la venta en el POS y listado en el Catálogo de Productos.

#### 3. Análisis Técnico y Base de Datos (Para el Equipo)
- **Opción A (Recomendada):** 
  - En la tabla `esp_productos` agregar la columna `es_elaborado BOOLEAN DEFAULT FALSE` o `tipo_producto ENUM('REVENTA', 'ELABORADO')`.
  - Crear una relación `1 a 1` o `1 a N` entre `esp_productos` y `recetas`.
  - El backend expone un endpoint transaccional `@Transactional`: `POST /api/recetas/elaborado` que inserta simultáneamente en `esp_productos`, `recetas` y `recetas_detalles`.
- **Opción B:**
  - Mantener la relación actual `receta.esp_producto_id`, pero hacer que el endpoint del backend reciba los datos del producto nuevo, lo persista internamente primero y luego cree la receta asociada.

---

### 📌 Punto 6: Asignación y Creación Dinámica de Categorías
*En la pantalla productos falta asignar categoría al crear y editar. ¿Dónde y cómo se crean las categorías?*

#### 1. Situación Actual y Problema
- En el Catálogo y POS existen los chips para filtrar por categoría, pero en el formulario de creación y edición de productos (`ProductoFormDialog`) **falta el selector de categoría**.
- No existe una interfaz para que el usuario cree sus propias categorías comerciales (ej. "Golosinas", "Lácteos", "Pastelería").

#### 2. Propuesta Funcional y UX
1. **En el Formulario de Producto (`ProductoFormDialog`):**
   - Incorporar un campo `DropdownButtonFormField<Categoria>` obligatorio o con opción "Sin Categoría".
   - En modo edición, precargar la categoría actual del producto.
2. **¿Dónde se crean las categorías?**
   - **Solución Ágil (En el mismo formulario):** Al lado del desplegable de categorías, colocar un botón `+` (icono de agregar). Al presionarlo, abre un modal compacto para ingresar el nombre de la nueva categoría (ej. "Panadería"). Al confirmar, se guarda en backend y queda seleccionada inmediatamente en el desplegable sin perder los datos que el usuario ya venía tipeando.
   - **Solución Integral:** Añadir una pestaña o sección "Categorías" dentro de la pantalla de **Configuración** (`/settings`) o un botón de administración en el encabezado del Catálogo para editar nombres o desactivar categorías existentes.

#### 3. Requerimientos de Backend
- Validar que el endpoint `POST /api/categorias` y `GET /api/categorias` estén disponibles y vinculados en el controlador para altas rápidas desde el frontend.

---

### 📌 Punto 4: Baja Lógica (Soft Delete / Switch Activar-Desactivar) en Materia Prima
*Quitar el icono de eliminación física de materias primas y reemplazarlo por un mecanismo de activar/desactivar.*

#### 1. Situación Actual y Problema
- En la tabla de Materias Primas existía un icono de papelera / borrar.
- **Riesgo crítico de BD:** Borrar físicamente un insumo (`DELETE FROM materias_primas WHERE id = X`) provoca una violación de integridad referencial (`Foreign Key Constraint`) si el insumo ya está siendo utilizado en alguna receta histórica o en movimientos de stock previos.

#### 2. Propuesta Técnica y Funcional
- Eliminar por completo el botón de borrado físico en la UI de Materia Prima.
- Reemplazarlo por un control de estado **Activar / Desactivar** (un `Switch` o botón de estado con iconos `toggle_on` / `toggle_off`).
- **Comportamiento en Backend:**
  - La entidad `MateriaPrima` ya cuenta con el campo `activo (boolean)`.
  - El endpoint de actualización cambia `activo = false`.
- **Comportamiento en Frontend:**
  - Los insumos desactivados se ocultan de los desplegables al armar nuevas recetas.
  - En la tabla de materias primas pueden mostrarse con estilo atenuado o con un filtro "Ver activos / inactivos".
  - Las recetas previas conservan la trazabilidad histórica sin romperse.

---

## 🟡 NIVEL 2 — Lógica de Negocio y Flujo Operativo

---

### 📌 Punto 1: Rediseño del POS — Quitar botón "Agregar" y habilitar edición directa en el Carrito
*Quitar el input de cantidad previo y el botón 'Agregar'. Permitir ingresar cantidades directamente en la fila del carrito además de los botones +/-.*

#### 1. Referencia Visual
- **Captura 1:** `instrucciones/capturas con referencias/1-.png` (Muestra la cajita suelta de cantidad y el botón verde "Agregar" que deben eliminarse).
- **Captura 2:** `instrucciones/capturas con referencias/1--.png` (Muestra la columna `Cantidad` en el carrito con `- 1 +`).

#### 2. Situación Actual y Problema
- Actualmente, para sumar un producto hay que escribir la cantidad previa y pulsar "Agregar", o hacer clic en la tarjeta y luego ir modificando con botones de sumar y restar de a uno. Si el cliente lleva 24 unidades, presionar 24 veces el botón `+` es lento e incómodo.

#### 3. Propuesta de Rediseño
1. **En la grilla/catálogo del POS:**
   - Quitar el campo previo de texto y el botón "Agregar" (`1-.png`).
   - Al hacer clic o tap sobre la tarjeta del producto, este se agrega inmediatamente al carrito con cantidad 1 (o incrementa en +1 si ya estaba en el carrito).
2. **En la tabla del carrito (`1--.png`):**
   - En la fila donde aparece `- 1 +`, reemplazar el texto central estático `1` por un **cuadro de texto numérico editable (`TextField`)**:
     ```text
     [ - ]  [ 24 ]  [ + ]
     ```
   - El cajero puede:
     - Usar los botones `+` y `-` para ajustes rápidos de 1 en 1.
     - O hacer clic en la cajita y tipear directamente `24` o `1.5` (en productos por kilo/fraccionados).
   - Al cambiar el número, el subtotal y el total del carrito se recalculan en tiempo real.

---

### 📌 Punto 3: Pantalla Materia Prima — Unificación de Edición y Análisis de Stock Actual vs Stock Mínimo
*Unificar la edición que presenta iconos redundantes y evaluar la justificación de mantener Stock Actual y Stock Mínimo.*

#### 1. Referencia Visual
- **Captura 1:** `instrucciones/capturas con referencias/3.png` (Muestra la columna "Acciones" con dos iconos redundantes: ajuste de stock con deslizadores y edición con lápiz).
- **Captura 2:** `instrucciones/capturas con referencias/3-.png` (Muestra los campos "Stock Actual" y "Stock Mínimo" dentro del formulario).

#### 2. Unificación de Iconos Redundantes
- **Problema:** Tener un icono para "Ajustar Stock" y otro para "Editar" confunde al usuario, ya que ambos modifican valores del insumo y saturan la columna de acciones.
- **Solución:**
  - Dejar un **único botón de "Editar"** (icono de lápiz).
  - Al abrir el modal de edición, el usuario puede modificar los datos generales (nombre, unidad, costo, stock mínimo).
  - Dentro de ese mismo modal, incluir una sección clara para el **Ajuste de Stock** (Entrada / Salida / Corrección) con su respectivo motivo. Así se concentra toda la gestión en un solo diálogo unificado.

#### 3. Análisis de Negocio: ¿Por qué mantener o no Stock Actual vs Stock Mínimo?
- **¿Qué es el Stock Actual?**
  - Es la cantidad real que hay físicamente en la estantería (ej. 499 unidades).
  - **Dictamen: DEBE MANTENERSE OBLIGATORIAMENTE.** Sin este dato, el sistema no puede saber si alcanzan los insumos para producir una receta ni descontar stock cuando se elabora o vende un producto.
- **¿Qué es el Stock Mínimo?**
  - Es el límite de seguridad (ej. 50 unidades). No representa mercadería física, sino una **regla de alerta**.
  - **Dictamen: SE RECOMIENDA MANTENERLO, PERO EXPLICARLO MEJOR EN UI.** Es la base que dispara la advertencia visual de **"Stock Crítico"** cuando el stock actual cae por debajo de ese número, permitiendo al dueño del negocio saber cuándo reponer antes de quedarse sin materia prima para cocinar.
- **Mejora Propuesta:**
  - En el formulario de alta/edición, cambiar la etiqueta para evitar confusiones:
    - `"Stock Actual (físico en depósito)"`
    - `"Alerta de Stock Crítico (avisar cuando queden menos de:)"`

---

## 🟢 NIVEL 3 — Ajustes de Usabilidad y Refinamiento Visual (UX)

---

### 📌 Punto 2: Supresión del Ticket PDF Post-Venta
*Quitar la generación y visualización automática del ticket PDF tras confirmar la venta.*

#### 1. Referencia Visual
- **Captura 1:** `instrucciones/capturas con referencias/2-.png` (Diálogo de éxito con botón "Ver ticket" y "Nueva venta").
- **Captura 2:** `instrucciones/capturas con referencias/2--.png` (Visualizador del ticket PDF abierto).

#### 2. Situación Actual y Problema
- Al registrar una venta, el sistema muestra el botón "Ver ticket" que compila y abre un archivo PDF en el sistema. Para un comercio ágil de mostrador donde no se imprime ticket o donde el cliente no lo solicita, este paso es innecesario y entorpece la velocidad de atención.

#### 3. Propuesta
- En el modal de éxito de venta (`2-.png`):
  - **Quitar el botón "Ver ticket"**.
  - Mostrar únicamente la confirmación limpia: *"Venta registrada correctamente"* y el botón *"Nueva venta"* (o directamente volver al estado listo del carrito con un SnackBar no invasivo).
- Mantener la lógica interna del servicio desacoplada para cuando en el futuro se integre una impresora de comandas física vía USB/ESC-POS si el cliente lo requiere, pero sin obligar la visualización del archivo PDF en pantalla.

---

### 📌 Punto 7: Comportamiento Global de Modales (Cerrar al Clickear Fuera)
*Configurar todos los diálogos y ventanas modales para que se cierren al hacer clic fuera de ellos.*

#### 1. Situación Actual y Problema
- Actualmente, varios diálogos de la aplicación obligan a hacer clic explícitamente en el botón "Cancelar" o en la cruz para cerrarse. Si el usuario hace clic en el área oscura de fondo, el diálogo no se cierra.

#### 2. Propuesta Técnica
- En todas las llamadas a `showDialog(...)` a lo largo de las pantallas del proyecto:
  - Establecer explícitamente la propiedad:
    ```dart
    barrierDismissible: true,
    ```
  - Verificar que el `barrierColor` permita identificar claramente el fondo oscurecido.
  - Asegurar que al cerrarse por clic exterior se descarten los cambios no guardados sin lanzar errores de validación en consola.

---

## 🗺️ Mapa de Rutas y Archivos Involucrados para el Equipo

| Punto | Funcionalidad | Archivos Frontend | Archivos Backend / BD |
| :--- | :--- | :--- | :--- |
| **1** | POS: Carrito con input directo | `frontend/lib/screens/pos_screen.dart`<br>`frontend/lib/widgets/product_card.dart` | *No requiere cambios* |
| **2** | Quitar Ticket PDF | `frontend/lib/screens/pos_screen.dart` | *No requiere cambios* |
| **3** | Materia Prima: Unificar edición | `frontend/lib/screens/insumos_screen.dart` | *No requiere cambios* |
| **4** | Materia Prima: Activar/Desactivar | `frontend/lib/screens/insumos_screen.dart`<br>`frontend/lib/blocs/insumos/` | `backend/sgiu/.../MateriaPrima.java`<br>`InsumoController.java` |
| **5** | Receta como Producto Elaborado | `frontend/lib/screens/recetas_screen.dart`<br>`frontend/lib/blocs/recetas/` | `EspProducto.java`<br>`Receta.java`<br>`RecetaController.java`<br>`esp_productos (DDL)` |
| **6** | Asignación y Alta de Categorías | `frontend/lib/widgets/producto_form_dialog.dart`<br>`frontend/lib/screens/catalogo_screen.dart` | `CategoriaController.java`<br>`CategoriaService.java` |
| **7** | Modales `barrierDismissible: true` | Todos los `showDialog` en `screens/` y `widgets/` | *No requiere cambios* |

---

## ❓ Preguntas de Decisión para el Equipo de Desarrollo

1. **Sobre el Punto 5 (Recetas y Elaborados):**
   - ¿Prefieren que al crear una receta se inserte directamente un registro en `esp_productos` con un flag `es_elaborado = 1`, o prefieren mantener dos tablas independientes vinculadas por clave foránea? (Nuestra recomendación técnica es la primera, ya que unifica el control de stock, precios y catálogo).
2. **Sobre el Punto 6 (Categorías):**
   - ¿Aprobamos la creación rápida mediante botón `+` dentro del diálogo de producto, o quieren una pantalla dedicada de administración de categorías en el menú lateral?
