# Revisión del estado real de SGI-U

**Fecha de revisión:** 10/10/2026
**Rama revisada:** `lucre-develop` (creada hoy desde `develop`, mismo commit `d1ae239` del 22/09/2026)
**Método:** contraste de las 6 fuentes de `docs/fuentes/` contra el código, más la ejecución de los tests.

> **Avisos sobre el alcance de esta revisión**
> 1. **Hay cambios locales sin commitear** en `frontend/lib/main.dart`, `frontend/lib/screens/login_screen.dart` y `frontend/lib/services/api_service.dart`: son `print()` de depuración y la navegación a `CatalogoScreen` al autenticarse. **Los tests del frontend se corrieron con esos cambios incluidos.** No se tocaron.
> 2. **El último `git fetch` es del 22/09/2026 14:40.** La auditoría (23/09) y el análisis ejecutivo (24/09) son posteriores, y este repo local no tiene nada que haya llegado a GitHub después de esa fecha. Por ejemplo, los tests que cita la auditoría (`RecetaServiceTest`, `VentaFraccionadaTest`, etc.) **no existen en ninguna rama local ni remota conocida**. Hasta no hacer un fetch, todo lo que figura acá como "PENDIENTE" significa *pendiente en la copia local*.
> 3. Los estados se asignaron leyendo el código, no probando la app manualmente. "HECHO" significa que el código existe y cumple lo que pide la tarea.

---

## 1. Rama de trabajo

- La revisión se hizo sobre `lucre-develop`, como se pidió. Es idéntica a `develop` (`d1ae239`, 22/09, Lucrecia).
- No se cambió de rama, porque hay cambios locales sin commitear.

## 2. Git: ramas no mergeadas

**Rama principal:** formalmente es `main`, pero está **abandonada**: su último commit es del 17/05/2026 y quedó **129 commits detrás de `develop`**. En la práctica, la rama de integración es `develop`.

- **No mergeadas en `main`:** todas, porque `main` no recibe merges desde mayo.
- **No mergeadas en `develop`:** ninguna. Todas las ramas que se ven localmente ya están contenidas en `develop`.

| Rama | Último commit | Commits vs `main` | Contenido principal | Estado |
|---|---|---|---|---|
| `develop` / `lucre-develop` | 22/09 Lucrecia — Punto 1 POS | 129 | Todo lo de abajo + QA de Luciano (22/09) + Punto 1 | Rama viva |
| `origin/feat/modelo-bd-mvp-y-backup-b2` | 21/09 Victoria — fix tests 114/114 | 107 | `backup/BackupDumpJob`, `BackupUploader`, `BackupController`, entidades nuevas (Categoría, MateriaPrima, Receta, Pedido, ConfiguracionNegocio), 24 archivos de test | Ya en `develop` |
| `origin/develop-despliegue2-Leo` | 21/09 Leo — logout por 401 | 81 | Ajuste de stock vía `/api/productos/stock`, logout automático por 401, fixes de ticket PDF | Ya en `develop` |
| `feat/A.2.1-validacion-dtos` | 28/08 Lucrecia | 76 | `@Positive` / `@NotBlank` en DTOs, `@Valid` en VentaController. **También cambió el puerto de la BD de 3307 a 3306** (ver Riesgos) | Ya en `develop`; remoto borrado |
| `feat/A.1.1-login-backend` | 28/08 Lucrecia | 75 | 401 en login y captura de excepciones JWT | Ya en `develop`; remoto borrado |
| `feat/fase5-simulacro` | 25/08 Lucio (merge PR #59) | 74 | mDNS, ServerStore, permisos Android | Ya en `develop`; remoto borrado |
| `estudio-despliegue` | 03/08 Lucrecia | 49 | Launcher, MdnsConfig, instance.json, firewall con UAC (C1.x–C4.1) | Ya en `develop`; remoto borrado |
| `iteracion-2-frontend` | 18/05 Lucrecia | 1 | CRUD de productos con BLoC (FT-4/5/6) | Ya en `develop`; remoto borrado |
| `iteracion-2-backend` | 17/05 Lucrecia | 3 | POST/PUT de productos y baja lógica (BK-5/6/7) | Ya en `develop`; remoto borrado |

Las 8 ramas locales marcadas `[gone]` **no tienen trabajo perdido**: todo su contenido está en `develop`.

## 3. Tests

| Suite | Comando | Resultado |
|---|---|---|
| Backend | `./mvnw -B test` (JDK 24 local; el proyecto pide Java 21) | ✅ **115 tests, 0 fallos, 0 errores, 0 skip**. BUILD SUCCESS en 27 s |
| Frontend | `flutter analyze` | ✅ **No issues found** |
| Frontend | `flutter test` | ✅ **185/185 OK** (incluye los cambios locales sin commitear) |

Observaciones:
- Los tests de backend corren con H2 (perfil `test`), no con MariaDB. Ningún test valida SQL real, concurrencia ni `data.sql`.
- La auditoría del 23/09 reporta "22 tests, 2 skip" con archivos que **no están en este repo** (`RecetaServiceTest`, `VentaServiceStockElaboradoTest`, `InsumoSoftDeleteTest`, `ProductoActualizarCategoriaTest`, `VentaFraccionadaTest`). Se hizo sobre otra copia (rutas `C:/Users/vicki/...`).
- Hay warnings no bloqueantes: Mockito se auto-adjunta como agente (dejará de funcionar en JDK futuros) y `spring.jpa.open-in-view` está activo por defecto.

---

## 4. Tabla de pendientes

Rutas abreviadas: `B/` = `backend/sgiu/src/main/java/com/sgiu_group/sgiu/`, `F/` = `frontend/lib/`, `R/` = `backend/sgiu/src/main/resources/`.

### 4.1 Incidencias UAT de agosto (Despliegue-2, §2 y Anexo)

| ID | Origen | Descripción | Estado | Evidencia | Nota |
|---|---|---|---|---|---|
| INC-001 | UAT ago. | Login sin manejo de errores | HECHO | `B/controllers/auth/AuthController.java:90`, `F/services/api_service.dart:147` | Backend devuelve 401; el frontend mapea 400/401/403 a "Credenciales incorrectas" |
| INC-002 | UAT ago. | Perfil vendedor / RBAC | PENDIENTE | `B/models/entities/EspUsuario.java:15-28` (sin campo rol), `B/config/DataSeeder.java:26-28` | Solo existe `admin`. El único `@PreAuthorize` es `isAuthenticated()` (`B/controllers/DashboardController.java:13`) |
| INC-003 | UAT ago. | Atajos F1/F12 | PENDIENTE | No hay `CallbackShortcuts` ni `LogicalKeyboardKey` en `F/` | Igual que la tarea B.1 |
| INC-004 | UAT ago. | Ajuste de stock no funcional | HECHO | `B/controllers/ProductoController.java:55` (`PUT /stock/{codigo}`), commit `9978793` | |
| INC-005 | UAT ago. | Validación de stock negativo | HECHO | `B/services/ProductoService.java:220-221` | Lanza `IllegalArgumentException`, que se responde con 400 |
| INC-006 | UAT ago. | Exportación de reporte fallida | PARCIAL | `F/services/pdf_service.dart:213` (`Printing.sharePdf`) | Exporta a PDF por "compartir". No hay Excel (B.2.x) ni guardado en Descargas |
| INC-007 | UAT ago. | Alerta de stock BAJO | HECHO | `B/repositories/ArticuloStockRepository.java:17` (`<=`), `F/screens/dashboard_screen.dart:588` | Rojo para AGOTADO y ámbar para BAJO |
| INC-008 | UAT ago. | Inconsistencia visual | PARCIAL | `F/main.dart:95` (`ColorScheme.fromSeed`) | 13 archivos fuera de `theme/` siguen usando `Color(0x...)` literal |
| INC-009 | UAT ago. | Sesión / JWT expirado | HECHO | `B/security/JwtFilter.java:58-59`, `F/services/api_service.dart:69-72`, `F/blocs/auth/auth_bloc.dart:23`, `F/widgets/side_menu.dart:166` | Interceptor de 401, logout automático y botón "Cerrar Sesión" |
| INC-010 | UAT ago. | Ajuste de stock y visualización | HECHO | Ídem INC-004 + fix "Stock resultante" en `F/widgets/producto_form_dialog.dart` | |
| INC-011 | UAT ago. | Tabla de balance vacía | HECHO | `F/utils/parsers.dart`, `F/screens/balance_screen.dart:282` | Corregido con parsing defensivo (ronda del 24/08). No re-verificado a mano |
| INC-012 | UAT ago. | Filtros del dashboard | PARCIAL | `F/screens/dashboard_screen.dart:46` | Funciona el filtro por método de pago; el de producto no (mismatch id/código) |
| INC-013 | UAT ago. | Enlaces de navegación del dashboard | PENDIENTE | `F/screens/dashboard_screen.dart` no tiene `Navigator` hacia otros módulos | |

### 4.2 Tareas del plan de despliegue

| ID | Origen | Descripción | Estado | Evidencia | Nota |
|---|---|---|---|---|---|
| P.1 | Plan desp. | Deps backend (JmDNS, ZXing, sin H2 runtime) | HECHO | `backend/sgiu/pom.xml` (jmdns 3.5.10, zxing 3.5.3) | H2 solo en scope test |
| P.2 | Plan desp. | AbstractIntegrationTest + perfiles | HECHO | `backend/sgiu/src/test/.../AbstractIntegrationTest.java` | El perfil `integration` (MariaDB real) no lo usa ningún test |
| P.3 | Plan desp. | Deps frontend | HECHO | `frontend/pubspec.yaml` (multicast_dns, qr_flutter, excel, file_picker, path_provider, url_launcher, share_plus) | `excel` y `qr_flutter` están declaradas pero no se usan |
| C.3.1 | Plan desp. | Launcher.java | HECHO | `B/Launcher.java:18-25, 217-221` | Ver riesgo R-1 (el Launcher levanta la BD en 3307 pero `application.yml` apunta a 3306) |
| C.3.2 | Plan desp. | InstallationIdentity (UUID) | HECHO | `B/InstallationIdentity.java:14` | |
| C.3.3 | Plan desp. | MdnsConfig `_sgiu._tcp` | HECHO | `B/config/MdnsConfig.java:24`, `B/config/JmDnsBeanConfig.java` | |
| C.3.4 | Plan desp. | DiscoveryService + setBaseUrl | HECHO | `F/services/discovery_service.dart:21`, `F/services/reconnection_service.dart:16` | Timeout de 3 s |
| C.3.5 | Plan desp. | Permisos Android Wi-Fi/multicast | HECHO | `frontend/android/app/src/main/AndroidManifest.xml` | |
| C.3.6 | Plan desp. | firewall-windows.bat idempotente | HECHO | `packaging/scripts/firewall-windows.bat:8,14`, `packaging/test/firewall-test.ps1` | La regla se llama "SGI-U Backend" |
| C.3.7 | Plan desp. | Endpoint QR `/api/qr/image` | PENDIENTE | No existe `QrController` en `B/controllers/` | ZXing está en el pom sin uso |
| C.3.8 | Plan desp. | Connect screen (QR / fallback) | PENDIENTE | No hay `connect_screen.dart` | Sin mDNS no hay forma de vincular un móvil |
| C.3.9 | Plan desp. | Persistencia de IP con TTL de 24 h | HECHO | `F/services/server_store.dart:18` | |
| D.2 | Plan desp. | ShutdownManager | HECHO | `B/config/ShutdownManager.java:21` | |
| A.1.1 | Plan desp. | Login backend 401 + JWT | HECHO | `B/controllers/auth/AuthController.java:90`, `B/security/JwtFilter.java:58` | |
| A.1.2 | Plan desp. | AuthBloc con DI y mensajes limpios | HECHO | `F/blocs/auth/auth_bloc.dart` (ronda 5, commit `73f3a1c`) | |
| A.2.1 | Plan desp. | Validación de DTOs | HECHO | `B/models/dtos/LineaVentaDTO.java:7`, `B/models/dtos/StockRequestDTO.java:10` | |
| A.2.2 | Plan desp. | MovimientoStock + `@Version` | PENDIENTE | No existe la entidad; `@Version` no aparece en ningún lugar de `B/` | Igual que el hallazgo C-5 |
| A.2.3 | Plan desp. | Decremento atómico de stock | PENDIENTE | `B/services/VentaService.java:100-101` (lee, resta y guarda) | No hay `@Modifying` en `ArticuloStockRepository` |
| A.2.4 | Plan desp. | Alinear URLs `/crear`, `/editar`, `/stock` | HECHO | `F/services/api_service.dart` usa `/api/productos/crear`, `/editar/$codigo`, `/stock/$codigo` | |
| A.3.1 | Plan desp. | Test de regresión del KPI de stock bajo | HECHO | `backend/sgiu/src/test/.../DashboardIntegrationTest.java` | |
| A.3.2 | Plan desp. | Mostrar el KPI de stock bajo | PARCIAL | `F/models/dashboard_models.dart:24` | El dato se parsea pero ninguna tarjeta de `dashboard_screen.dart` lo muestra |
| A.3.3 | Plan desp. | Pull-to-refresh de KPIs | PENDIENTE | No hay `RefreshIndicator` en `F/` | |
| A.3.4 | Plan desp. | Ámbar para BAJO | HECHO | `F/screens/dashboard_screen.dart:588` | |
| D.4.1 | Plan desp. | Pagos mixtos (backend) | PENDIENTE | `B/models/dtos/VentaRequestDTO.java` (un solo `metodoPago`), `B/services/VentaService.java:118-120` (un solo `PagoVenta`) | El MVP sí lo pide (normalización de Pago_Venta) |
| D.4.2 | Plan desp. | Pagos mixtos (frontend) | PENDIENTE | `F/widgets/payment_method_selector.dart:29-33` (`RadioListTile`, un método) | |
| D.4.3 | Plan desp. | Deshabilitar "CONFIRMAR COBRO" | PARCIAL | `F/screens/pos_screen.dart:693` | No se deshabilita; muestra un aviso si no hay método elegido. Cubre RF12 en lo funcional |
| D.12 | Plan desp. | Precio congelado (CartItem) | HECHO | `F/models/cart_item.dart:7` | |
| D.7.1 | Plan desp. | TicketService PDF | HECHO | `F/services/ticket_service.dart:19` | Acepta logo |
| D.7.2 | Plan desp. | Botón "Ver ticket" | OBSOLETO | `F/screens/pos_screen.dart:97` | Está hecho, pero el Punto 2 del 22/09 pide quitarlo |
| D.9.1 | Plan desp. | Importación CSV (backend) | PENDIENTE | No existe `/api/productos/importar` | |
| D.9.2 | Plan desp. | Importación CSV (UI) | PENDIENTE | `FilePicker` solo se usa para el logo (`F/screens/settings_screen.dart:79`) | |
| B.2.1 | Plan desp. | ExcelService | PENDIENTE | No existe `excel_service.dart` | |
| B.2.2 | Plan desp. | Botón Exportar a Excel | PENDIENTE | — | Hoy se exporta a PDF (ver INC-006) |
| B.2.3 | Plan desp. | Guardado en Descargas | PENDIENTE | No se usa `getDownloadsDirectory` | |
| B.1 | Plan desp. | Atajos de teclado POS | PENDIENTE | Ídem INC-003 | |
| C.1.1 | Plan desp. | AppTheme centralizado | PARCIAL | `F/main.dart:95`, `F/theme/app_colors.dart` | No hay clase `AppTheme`; el seed está inline en `main.dart` |
| C.1.2 | Plan desp. | Quitar colores hardcodeados | PENDIENTE | 13 archivos con `Color(0x` fuera de `theme/` | |
| C.2 | Plan desp. | AnimatedSwitcher login→app | PENDIENTE | No hay `AnimatedSwitcher` | El cambio local sin commitear usa `pushAndRemoveUntil` |
| D.1.1 | Plan desp. | Logo (asset + LogoWidget) | PARCIAL | `F/screens/settings_screen.dart:218` (logo cargable) | Se reemplazó por un logo configurable guardado en la BD. No hay `LogoWidget` ni `logo.png` |
| D.1.2 | Plan desp. | Logo en login, menú y PDFs | PARCIAL | `F/services/ticket_service.dart:22-31` | Aparece en el ticket. No aparece en el login ni en `side_menu.dart` |
| D.3 | Plan desp. | Categoría "Servicios" en movimientos | PENDIENTE | No se encuentra `'Servicios'` en `F/` | El seed usa `SERVICIO` |
| D.5 | Plan desp. | Terminología comercial | PENDIENTE | No se encuentran "Panel de control" ni "Disponible:" | |
| D.6.1 | Plan desp. | Tablas sin scroll horizontal | PENDIENTE | `F/screens/balance_screen.dart:520`, `F/screens/movimientos_screen.dart:226` | Siguen con `minWidth` y scroll; no ocultan columnas |
| D.6.2 | Plan desp. | POS en GridView | PENDIENTE | `F/screens/pos_screen.dart:161-163` | Sigue como carrusel horizontal |
| D.8.1 | Plan desp. | Categoría + filtro en `GET /api/productos` | HECHO | `B/controllers/ProductoController.java:24-25` | Se implementó como entidad `Categoria`, no como String |
| D.8.2 | Plan desp. | Chips de categoría en catálogo | HECHO | `F/screens/catalogo_screen.dart:166` | |
| D.10 | Plan desp. | Tooltips financieros en KPIs | PENDIENTE | Solo hay `Tooltip` en `F/screens/insumos_screen.dart` | |
| D.11.1 | Plan desp. | AyudaDialog | PENDIENTE | No existe | |
| D.11.2 | Plan desp. | Ayuda en menú y dashboard | PENDIENTE | No existe | |
| CI.1 | Plan desp. | GitHub Actions | PENDIENTE | No existe `.github/workflows/` | |

### 4.3 Feedback UAT del 22/09 (`FEEDBACK_Y_AJUSTES_PENDIENTES.md`)

| ID | Origen | Descripción | Estado | Evidencia | Nota |
|---|---|---|---|---|---|
| Punto 1 | Feedback 22/09 | Cantidad editable en el carrito y sin botón "Agregar" | PARCIAL | Commit `d1ae239`; `F/screens/pos_screen.dart:444, 525` (`int.tryParse`) | Solo acepta enteros. Para `1.5` falta la migración a BigDecimal (A-1) |
| Punto 2 | Feedback 22/09 | Quitar el ticket PDF post-venta | PENDIENTE | `F/screens/pos_screen.dart:83-97` | |
| Punto 3 | Feedback 22/09 | Un solo botón Editar y etiquetas claras de stock | PENDIENTE | `F/screens/insumos_screen.dart:554, 562` (dos íconos), `:171, 184` (etiquetas viejas) | |
| Punto 4 | Feedback 22/09 | Activar/desactivar insumos | PENDIENTE | `B/services/MateriaPrimaService.java:33-34` (`findByActivoTrue`); no hay PATCH | Igual que A-5 |
| Punto 5 | Feedback 22/09 | Receta como alta de producto elaborado | PENDIENTE | `F/screens/recetas_screen.dart:335-341` (sigue pidiendo un producto existente); no hay `POST /api/recetas/elaborado` | Depende de la decisión D-1 |
| Punto 6 | Feedback 22/09 | Categoría en el formulario de producto + alta rápida | PENDIENTE | `F/widgets/producto_form_dialog.dart:229` (solo reenvía la categoría existente como texto); el frontend nunca llama a `/api/categorias` | El backend está listo (`B/controllers/CategoriaController.java:21,26`), salvo la desasignación (A-4) |
| Punto 7 | Feedback 22/09 | Modales que cierran al hacer clic afuera | PARCIAL | `barrierDismissible: false` en `F/screens/balance_screen.dart:88`, `insumos_screen.dart:71`, `pedidos_screen.dart:76` | El resto usa el valor por defecto (`true`) |

### 4.4 Análisis ejecutivo del 24/09

| ID | Origen | Descripción | Estado | Evidencia | Nota |
|---|---|---|---|---|---|
| C-1 | An. ejecutivo | `data.sql` inserta columnas inexistentes en `configuracion_negocio` | PENDIENTE | `R/data.sql:11` (`nombre_comercio`, `logo_path`) vs `B/models/entities/ConfiguracionNegocio.java:14,21` | Falla en silencio (`continue-on-error`) |
| C-2 | An. ejecutivo | Texto en la FK `lineas_venta.codigo_producto` | PENDIENTE | `R/data.sql:50-58` | |
| C-3 | An. ejecutivo | Totales de venta ≠ suma de líneas | PENDIENTE | `R/data.sql:43-47` vs `:51-58` | |
| C-4 | An. ejecutivo | Doble descuento (producto final + insumos) | PENDIENTE | `B/services/VentaService.java:62, 67-75, 89-101` | Depende de la decisión D-1. Además redondea insumos hacia arriba (ver R-4) |
| C-5 | An. ejecutivo | Sin `@Version` ni concurrencia | PENDIENTE | No hay `@Version` en `B/` | Igual que A.2.2 y A.2.3 |
| A-1 | An. ejecutivo | Cantidades Integer | PENDIENTE | `B/models/entities/ArticuloStock.java:16,19`, `LineaVenta.java:23`, `MateriaPrima.java:37,40`, `LineaVentaDTO.java:8` | `RecetaDetalle.java:30` ya usa BigDecimal |
| A-2 | An. ejecutivo | `UPDATE` de stock en cada arranque | PENDIENTE | `R/data.sql:80-81` + `R/application.yml:33` (`mode: always`) | |
| A-3 | An. ejecutivo | `StockInsuficienteException` responde 500 | PENDIENTE | `B/exceptions/GlobalExceptionHandler.java:109-115` | Peor que lo reportado: el 500 dice "No se pudo generar el Dashboard" para cualquier error |
| A-4 | An. ejecutivo | No se puede desasignar una categoría | PENDIENTE | `B/services/ProductoService.java:167` | |
| A-5 | An. ejecutivo | Insumos inactivos ocultos, sin PATCH | PENDIENTE | `B/services/MateriaPrimaService.java:34` | |
| A-6 | An. ejecutivo | Sin Flyway (`ddl-auto: update`) | PENDIENTE | `R/application.yml:21` | |
| M-1 | An. ejecutivo | `RecetaDetalleRequestDTO` sin `@Positive` | PENDIENTE | `B/models/dtos/RecetaDetalleRequestDTO.java` | |
| M-2 | An. ejecutivo | El 400 por tipo inválido no se distingue | PENDIENTE | `B/exceptions/GlobalExceptionHandler.java:28` | |
| M-3 | An. ejecutivo | `metodo_pago` VARCHAR libre | PENDIENTE | `B/services/VentaService.java:118`, `B/services/PedidoService.java` (`toUpperCase()` libre) | |
| M-4 | An. ejecutivo | El saldo no se recalcula en `addAbono()` | PARCIAL | `B/models/entities/Pedido.java:65`; el recálculo está en `B/services/PedidoService.java:107-109` | El invariante se cumple en el flujo actual, pero lo mantiene el servicio y no la entidad |
| B-1 | An. ejecutivo | `esp_usuarios` sin auditoría | PENDIENTE | `B/models/entities/EspUsuario.java:15` (no extiende BaseEntity) | |
| B-2 | An. ejecutivo | Índices para el dashboard | PENDIENTE | Sin `@Index` sobre `ventas.fecha_hora` y similares | |
| B-3 | An. ejecutivo | Escala decimal inconsistente | PENDIENTE | Ídem A-1 | |

### 4.5 Requerimientos de Sandra (acta de reunión, Despliegue-2)

| ID | Origen | Descripción | Estado | Evidencia | Nota |
|---|---|---|---|---|---|
| S-1 | Reunión Sandra | Stock de materia prima separado del producto final | PARCIAL | `B/models/entities/MateriaPrima.java`, `B/controllers/InsumoController.java`, `F/screens/insumos_screen.dart` | Hay dos stocks, pero son enteros (no se pueden cargar 100 g) y la venta descuenta mal (C-4, R-4) |
| S-2 | Reunión Sandra | Categorías y búsqueda en el POS | HECHO | `F/screens/pos_screen.dart:201-220` (chips), búsqueda (commit `d1ae239`) | Las categorías no se pueden asignar desde la UI (Punto 6) |
| S-3 | Reunión Sandra | Reporte de ventas por producto y categoría | PARCIAL | Backend `B/services/DashboardService.java:84, 161` (categoría más vendida); frontend solo top productos (`F/screens/dashboard_screen.dart:600`) | El dashboard no muestra la categoría más vendida |
| S-4 | Reunión Sandra | Costo, precio y margen; recálculo al subir costos | PARCIAL | `B/models/entities/EspProducto.java:25-33`, `B/services/MateriaPrimaService.java:86-123` (recálculo en cascada) | Hay recálculo vía recetas. Falta una herramienta masiva de "subir precios X%" para productos de reventa |
| S-5 | Reunión Sandra | Pedidos con seña, búsqueda por celular/nombre, una sola venta | PARCIAL | `B/controllers/PedidoController.java:22-42`, `F/screens/pedidos_screen.dart`, `F/blocs/pedidos/pedidos_bloc.dart:46` | El pedido **no se vincula a un producto** (solo tiene `descripcion`), **ni la seña ni el saldo generan un movimiento financiero** y no descuentan stock. Ver R-5 |
| S-6 | Reunión Sandra | Personalización (nombre, logo, datos) | HECHO | `B/controllers/ConfiguracionController.java:17,22`, `F/screens/settings_screen.dart` | El seed de configuración falla (C-1) |
| S-7 | Reunión Sandra | Packaging y extras en el precio final | PARCIAL | `F/screens/recetas_screen.dart:412` ("Costos Adicionales (Packaging, etc.)") | Es un monto fijo por receta; no hay catálogo de insumos de packaging ni extras para Regalería |
| S-8 | Reunión Sandra | Tarjeta de ganancia del día en Movimientos | PARCIAL | `F/screens/balance_screen.dart:404` ("Ganancia Real"), `B/services/MovimientoService.java:87` | Está en Balance y por rango, no en Movimientos ni "del día" |
| S-9 | Reunión Sandra | Backup | PARCIAL | Ver 4.6 | La implementación actual **no respalda datos** |

### 4.6 Propuesta de backup a Backblaze B2 (Victoria y Lucio, sept. 2026)

| ID | Origen | Descripción | Estado | Evidencia | Nota |
|---|---|---|---|---|---|
| B2-1 | Propuesta B2 | `BackupDumpJob` (cron 03:30, catch-up al arrancar) | PARCIAL | `B/backup/BackupDumpJob.java:37-79` | El scheduling existe. Depende de que `mariadb-dump` esté en el PATH, y en el instalador no lo está. Si falla, el **fallback genera un archivo sin datos** que se presenta como "respaldo consistente" (`:141-162`). Los 3 dumps de `backend/sgiu/backups/` pesan 177 bytes y no tienen datos |
| B2-2 | Propuesta B2 | `BackupUploader` (subida a B2) | PENDIENTE | `B/backup/BackupUploader.java:40-45` | **Es un stub**: registra "subido exitosamente a Backblaze B2" sin subir nada. No hay SDK S3 en el pom. `listarBackups` lista archivos locales, no B2 |
| B2-3 | Propuesta B2 | Código de Cliente | PARCIAL | `B/models/entities/ConfiguracionNegocio.java:16-17`, `F/screens/settings_screen.dart:61,113` | Se puede editar en Ajustes. El seed `SGIU-SANDRA-001` no se carga (C-1). Si está vacío se usa `SGIU-DEFAULT` |
| B2-4 | Propuesta B2 | Pantalla "Instalación nueva / Restaurar instalación existente" | PENDIENTE | No aparece "restaur" ni "instalación nueva" en el Launcher ni en `F/` | No hay flujo de restauración, ni asistido ni documentado como script |
| B2-5 | Propuesta B2 | Keys separadas de escritura y lectura, Object Lock, lifecycle de 30 dumps | PENDIENTE | `B/backup/BackupUploader.java:21-28` (una sola key por variable de entorno) | Es configuración del lado B2, fuera del repo |
| B2-6 | Propuesta B2 | Endpoint de backup manual | HECHO (extra) | `B/controllers/BackupController.java:27,46` | No estaba en la propuesta. Requiere login, pero cualquier usuario puede dispararlo |

---

## 5. Inventario

### 5.1 Pantallas de Flutter

El único criterio responsive global es `esMobile()` (`F/utils/es_mobile.dart:4`, ancho < 900 px), que solo cambia el menú lateral por un drawer en `F/widgets/app_scaffold.dart:24`. **No existe ningún layout específico para tablet**: el MVP prometía un 70/30 para tablet y una "thumb zone" para móvil.

| Pantalla | Archivo | Desktop | Tablet | Móvil | Nota |
|---|---|---|---|---|---|
| Login | `login_screen.dart` | ✅ dos paneles (>900 px, `:63`) | ≈ usa el layout móvil | ✅ panel único | Es la única pantalla con dos layouts reales |
| Dashboard | `dashboard_screen.dart` | ✅ | ≈ | ⚠️ solo se adapta la cabecera (<700 px, `:193`) | Las tablas pueden desbordar |
| POS | `pos_screen.dart` | ✅ 70/30 fijo (`:119-120`) | ✅ el 70/30 sirve | ❌ el mismo 70/30 se comprime | No hay thumb zone ni barra inferior |
| Catálogo | `catalogo_screen.dart` | ✅ | ≈ | ⚠️ DataTable con scroll horizontal | |
| Insumos | `insumos_screen.dart` | ✅ | ≈ | ❌ sin LayoutBuilder | |
| Recetas | `recetas_screen.dart` | ✅ | ≈ | ❌ sin LayoutBuilder | |
| Pedidos | `pedidos_screen.dart` | ✅ | ≈ | ❌ sin LayoutBuilder | |
| Movimientos | `movimientos_screen.dart` | ✅ | ≈ | ⚠️ tabla con scroll horizontal | |
| Balance | `balance_screen.dart` | ✅ | ≈ | ⚠️ las tarjetas se adaptan, la tabla no | |
| Ajustes | `settings_screen.dart` | ✅ | ≈ | ❌ sin LayoutBuilder | |

Leyenda: ✅ layout pensado · ≈ hereda el de desktop sin ajustes · ⚠️ adaptación parcial · ❌ ninguna.

### 5.2 Módulos y endpoints del backend

| Módulo | Endpoints | Nota |
|---|---|---|
| Auth | `POST /api/auth/login`, `POST /api/auth/register` | **`register` es público** (ver R-3) |
| Productos | `GET /api/productos?categoria=`, `POST /crear`, `PUT /editar/{codigo}`, `PUT /stock/{codigo}` | |
| Categorías | `GET /api/categorias`, `POST /api/categorias` | Sin PUT ni DELETE |
| Insumos | `GET /api/insumos`, `GET /{id}`, `POST`, `PUT /{id}`, `POST /{id}/ajuste-stock` | Sin cambio de estado |
| Recetas | `GET`, `GET /{id}`, `GET /producto/{codigo}`, `POST`, `PUT /{id}`, `DELETE /{id}` | No hay `/elaborado` |
| Ventas | `POST /api/ventas` | Un solo método de pago |
| Pedidos | `GET /api/pedidos?q=`, `GET /{id}`, `POST`, `POST /{id}/abonar`, `POST /{id}/cancelar` | |
| Movimientos | `GET /api/movimientos`, `POST /api/movimientos` | Sin paginación en el servidor |
| Balance | `GET /api/balance` | |
| Dashboard | `GET /api/dashboard` | |
| Configuración | `GET /api/configuracion`, `PUT /api/configuracion` | |
| Backups | `GET /api/backups`, `POST /api/backups/ejecutar` | |
| Infraestructura | `Launcher`, `InstallationIdentity`, `MdnsConfig`, `JmDnsBeanConfig`, `ShutdownManager`, `DataSeeder`, `BackupDumpJob` | |

⚠️ El frontend llama a `GET /api/finanzas/resumen` (`F/services/api_service.dart:220`), **que no existe en el backend**.

### 5.3 Entidades y tablas

| Entidad | Tabla | Notas |
|---|---|---|
| EspProducto | `esp_productos` | precio, costo, % ganancia, unidad, categoría, activo. Sin `es_elaborado` |
| ArticuloStock | `articulos_stock` | `cantidad` y `stock_minimo` Integer |
| Categoria | `categorias` | activo |
| MateriaPrima | `materias_primas` | `stock_actual` y `stock_minimo` Integer; FK opcional a producto |
| Receta | `recetas` | 1 receta activa por producto |
| RecetaDetalle | `recetas_detalles` | `cantidad` DECIMAL(10,3) |
| Venta | `ventas` | `id_sesion_caja` y `creado_por_usuario` hardcodeados en 0 (`VentaService.java:48-49`) |
| LineaVenta | `lineas_venta` | `cantidad` Integer; precio y costo congelados |
| PagoVenta | `pagos_venta` | 1 por venta en la práctica |
| MovFinanciero | `movimientos_financieros` | `metodo_pago` VARCHAR libre |
| Pedido | `pedidos` | Sin vínculo a producto ni a venta |
| PedidoAbono | `pedidos_abonos` | Sin vínculo a un movimiento financiero |
| ConfiguracionNegocio | `configuracion_negocio` | nombre, código de cliente, logo (LONGBLOB), dirección, teléfono, descripción |
| EspUsuario | `esp_usuarios` | Sin rol ni auditoría |
| *Enums* | — | `UnidadMedida` (GRAMO, KILO, UNIDAD, CAJA, METRO, LITRO), `EstadoPedido`, `TipoMovimiento` |

Del MVP no se implementaron `Cliente`, `Proveedor`, `id_almacen` (multi-almacén) ni sesión de caja.

## 6. Despliegue

| Pieza | Archivo | Estado |
|---|---|---|
| jlink | `backend/sgiu/scripts/jlink-windows.bat` | Existe (13 módulos) |
| jpackage | `backend/sgiu/scripts/jpackage-windows.bat` | Existe. Usa `JarLauncher` como main class (ver contradicción 10) y no pone `mariadb-dump` en el PATH (ver B2-1) |
| Firewall | `packaging/scripts/firewall-windows.bat` + `packaging/test/firewall-test.ps1` | Existe. Lo invoca `B/Launcher.java:189` |
| Launcher | `B/Launcher.java` | Arranca MariaDB en 3307, inicializa el datadir, firewall, Spring y el frontend `.exe` |
| Guía de build | Despliegue-2, sección "Proceso de generación del instalador" | Rutas hardcodeadas a `C:\Users\vicki\...` |

**¿El instalador incluye la versión actual?** No se puede verificar, y hay indicios de que no:
- `backend/sgiu/packaging/` (con `app/` y `dist/`) está en `.gitignore` y **no existe en esta copia**. No hay ningún `.exe` ni JAR versionado.
- Hay **un solo número de versión para todo**: `SGI-U 1.0.0` (jpackage), backend `0.0.1-SNAPSHOT` y frontend `1.0.0+1`. Ningún instalador generado se puede distinguir de otro.
- El frontend se copia a mano ("paso 4–5: *si hubo cambios en el frontend*"), así que es fácil empaquetar un `.exe` viejo.
- El instalador generado con el código actual de `develop` **probablemente no arranca en una PC limpia** (R-1), y aunque arrancara no generaría backups reales (R-2).

---

## 7. Contradicciones entre documentos

1. **Motor de base de datos.** El MVP dice "PostgreSQL" (restricciones y riesgos) o "PostgreSQL/MySQL". El plan de despliegue y el código usan MariaDB. En la reunión se propuso SQLite o Supabase, y la propuesta B2 descarta Supabase. Nadie dejó registrada la decisión final sobre SQLite.
2. **Conectividad.** El MVP supone "conexión a internet estable". El manual de usuario dice "No necesita Internet". El backup B2 vuelve a necesitar internet.
3. **Usuarios por defecto.** El manual promete `vendedor / vendedor123`, pero el código solo crea `admin` (`DataSeeder.java:26-28`) y no hay roles. El MVP (casos de uso) promete un Cajero restringido con `@PreAuthorize`, y la UAT lo dejó para una "iteración futura".
4. **Contrato del login.** El plan de despliegue pide 401. La ronda frontend del 24/08 dice que el backend devolvía 400 y adaptó el frontend a eso. Después se implementó A.1.1 (401). Hoy los dos conviven.
5. **Ticket PDF.** D.7.1/D.7.2 lo piden y se implementó. El feedback del 22/09 (Punto 2) pide quitarlo. El manual dice "enviar por WhatsApp o imprimir".
6. **Venta fraccionada.** El análisis ejecutivo dice que es un "requisito confirmado del negocio". La auditoría del 23/09 lo plantea como pregunta abierta ("¿es requerimiento inmediato?"), y el análisis ejecutivo repite la pregunta en su §6.
7. **Cantidad de tests.** La auditoría y el análisis ejecutivo hablan de 22 tests y 2 skip. El commit de Victoria del 21/09 dice 114/114. Hoy son 115/0 skip. Las auditorías no se hicieron sobre `develop`.
8. **Puerto de la BD.** El plan dice 3307 (C4.1: "verifica application.yml puerto 3307"). El código tiene 3306 desde el commit `1921726` (28/08).
9. **Timeout de mDNS.** L2.1 pide 8 s, el manual dice "3 o 4 segundos" y el código usa 3 s.
10. **Main class del instalador.** La tarea V4.2 pide `--main-class com.sgiu_group.sgiu.Launcher`, pero el script usa `JarLauncher` (en la práctica delega en el `Launcher` del manifest, así que no rompe).
11. **Roles del equipo.** El MVP dice "Lucrecia: Líder Técnica". La reunión dice que Lucio quiere seguir como líder técnico y propone a Lucrecia como vendedora/analista.
12. **Pedidos y ventas.** Sandra pide que "seña + saldo = una sola venta". El código (Decisión D6, `PedidoService.java:111`) no crea ninguna venta: el pedido pagado no aparece en ventas, en balance ni en el dashboard.
13. **Gestión de productos.** El manual habla de "Eliminar: deslizar o botón Eliminar". El MVP y el código usan baja lógica (activo/inactivo).
14. **Alcance del MVP.** El MVP dice "no procesa pagos, sin QR". El plan agrega un QR de vinculación (C.3.7/C.3.8), que es otro uso del QR, no el de pagos. No es una contradicción real, pero conviene aclararlo.

## 8. Decisiones de negocio pendientes

| # | Decisión | Bloquea |
|---|---|---|
| D-1 | Modalidad de producción de Sandra: al paso, por lote o mixta (¿flag por producto?) | Punto 5, C-4 |
| D-2 | ¿Se vende por fracción (kg, L) ya? | A-1, Punto 1, S-1 |
| D-3 | ¿Qué pasa con una receta cuyo insumo se desactiva: bloquear o advertir? | Punto 4 |
| D-4 | ¿Categorías: alcanza con el botón "+" o hace falta una pantalla de administración? | Punto 6 |
| D-5 | ¿Un pedido pagado cuenta como venta (stock, balance, dashboard)? ¿La seña entra a caja el día que se cobra? | S-5 |
| D-6 | ¿Se mantiene o se quita el ticket PDF? ¿Hay impresora térmica? | Punto 2, D.7.x |
| D-7 | ¿Hacen falta roles (vendedor/cajero) para Sandra? | INC-002 |
| D-8 | Política de backup: frecuencia (RPO), quién crea la cuenta B2 y a nombre de quién, quién guarda la master key y cómo se entrega el Código de Cliente | B2-x |
| D-9 | Motor de BD definitivo: ¿MariaDB o se migra? (la reunión lo dejó abierto) | Todo el despliegue |
| D-10 | ¿Cómo fija precios Sandra (margen por producto, por categoría, aumento general)? | S-4 |
| D-11 | ¿`main` sigue siendo la rama de release? ¿Cuándo se mergea `develop` y se etiqueta v1.0.0 (tarea C6.2)? | Releases |
| D-12 | ¿Hace falta acceso desde móvil (mDNS/QR) o Sandra usa solo la PC? | C.3.7, C.3.8, layouts móviles |

## 9. Riesgos técnicos no mencionados en las auditorías

| # | Riesgo | Evidencia | Impacto |
|---|---|---|---|
| R-1 | **Puerto de BD desalineado**: el Launcher levanta MariaDB en 3307 y Spring se conecta a 3306 | `B/Launcher.java:25,66`; `R/application.yml:14`; commit `1921726` | Con el instalador actual, en una PC limpia el backend no encontraría la BD (salvo que haya otro MySQL en 3306) |
| R-2 | **El backup no respalda nada y dice que sí** | `B/backup/BackupUploader.java:44`; `BackupDumpJob.java:141-162`; dumps de 177 bytes en `backend/sgiu/backups/` | Falsa sensación de seguridad: si Sandra pierde el disco, no hay datos para restaurar. Es el riesgo más grave para la clienta |
| R-3 | **Registro de usuarios abierto en la LAN**: `/api/auth/**` es público y el servidor escucha en `0.0.0.0` | `B/config/SecurityConfig.java:46`; `B/controllers/auth/AuthController.java:108-125`; `R/application.yml:3` | Cualquiera en el Wi-Fi del local puede crearse una cuenta y obtener un JWT con acceso total (ventas, balance, backups) |
| R-4 | **Insumos redondeados hacia arriba** en cada venta | `B/services/VentaService.java:72` (`Math.ceil`) | Una receta con 0,2 kg descuenta 1 kg por unidad vendida. El stock de materia prima se vacía 5 veces más rápido de lo real |
| R-5 | **Las señas y los saldos de pedidos no entran a caja** | `B/services/PedidoService.java` no usa `MovFinanciero` | El balance y la "ganancia" no incluyen el dinero de tortas por pedido, que es el producto principal de Sandra |
| R-6 | **Error genérico engañoso**: cualquier excepción no mapeada responde "No se pudo generar el Dashboard" | `B/exceptions/GlobalExceptionHandler.java:109-115` | Soporte difícil; el cajero ve un mensaje sin sentido al vender sin stock |
| R-7 | **El seed de demo corre en producción** en cada arranque | `R/application.yml:33-34`; `R/data.sql:42-81` | Las ventas de demo (ids 100–104, "junio 2026") aparecen en el dashboard real de Sandra y el stock de los productos 4 y 5 se pisa |
| R-8 | **Secretos en el repo**: JWT secret, contraseña de la BD y `admin/admin123` | `R/application.yml:6,16`; `B/config/DataSeeder.java:28` | Todas las instalaciones comparten el mismo secret: un token de una instalación sirve en otra. No se obliga a cambiar la contraseña |
| R-9 | **Logs verbosos en producción**: `security: DEBUG` y `show-sql: true` | `R/application.yml:28,40` | Logs enormes en `%LOCALAPPDATA%` y posibles datos sensibles en ellos |
| R-10 | **Endpoint inexistente**: el frontend llama a `/api/finanzas/resumen` | `F/services/api_service.dart:220`; `F/blocs/finanzas/finanzas_bloc.dart:23-27, 72` | Después de crear un movimiento la llamada falla y el bloc muestra en silencio un resumen en $0 |
| R-11 | **Auditoría de ventas vacía** | `B/services/VentaService.java:48-49` (sesión y usuario = 0) | No se sabe quién vendió; los "anclajes de auditoría" del MVP no se usan |
| R-12 | **`main` abandonada y ramas de feature sin PR** (rondas directas sobre `develop`, "no push") | Sección 2; Despliegue-2, ronda 3 | Ya hubo pérdida de trabajo por no commitear (incidente de `Launcher.java` en C.3.2). No hay CI que proteja `develop` |
| R-13 | **Instalador sin trazabilidad de versión** y construido desde la máquina de una sola persona | Sección 6 | No se puede saber qué código tiene Sandra instalado |
| R-14 | **CORS sin PATCH** | `B/config/SecurityConfig.java:38` | Si se implementa `PATCH /api/insumos/{id}/estado` (A-5), los clientes web lo van a ver bloqueado |
| R-15 | **Sin tests contra MariaDB real** | Todos los tests usan H2 | Los errores de `data.sql` (C-1, C-2), los de concurrencia y los de dialecto solo aparecen en producción |
| R-16 | **Cambios locales sin commitear con `print()` de depuración** que registran el usuario y la URL | `git diff` en `main.dart`, `login_screen.dart`, `api_service.dart` | Si se commitean tal cual, quedan en el build de producción |
