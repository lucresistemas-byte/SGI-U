# Estrategia Integral de QA Automation - Frontend (Flutter) SGI-U

Este documento define la arquitectura y estrategia de pruebas automatizadas en 4 niveles para la aplicación cliente Flutter de **SGI-U (Sistema de Gestión Inteligente Unificado)**.

El objetivo es garantizar la estabilidad funcional, la correcta gestión del estado reactivo (BLoC), la integridad del modelo de datos y la fluidez de los flujos transaccionales críticos (como la atomicidad venta-stock-caja).

---

## 1. Roles y Responsabilidades del Equipo
* **Luciano & Lucio (QA Automation & Testing):**
  * Diseño, codificación y mantenimiento de suites de pruebas automáticas (Niveles 1 a 4).
  * Monitoreo de regresiones y reporte de métricas de cobertura.
  * Automatización de flujos de concurrencia y casos borde transaccionales.
* **Leonardo (Frontend & UI/UX Bugfixes):**
  * Mantenimiento de componentes visuales, integración de contratos de API y resolución de defectos reportados por la suite de pruebas.
  * Soporte en el desacoplamiento de widgets para facilitar pruebas unitarias y de widget.

---

## 2. Pirámide de Pruebas: Estrategia de 4 Niveles

```
        / \
       /   \      Nivel 4: End-to-End (integration_test/)
      /-----\
     /       \    Nivel 3: Pruebas de Widgets (test/widgets/)
    /---------\
   /           \  Nivel 1: Pruebas de Estado BLoC (test/blocs/)
  /-------------\
 /               \ Nivel 2: Pruebas Unitarias de Modelos & Parsers (test/models/, test/services/)
-------------------
```

---

### Nivel 1: Pruebas de Estado (BLoC Tests)
* **Directorio:** `test/blocs/`
* **Tecnologías:** `bloc_test`, `mocktail`, `flutter_test`.
* **Propósito:** Validar el comportamiento reactivo de la capa de lógica de negocio. Simula la emisión de eventos de usuario y verifica las secuencias determinísticas de estados emitidos (`build`, `act`, `expect`, `verify`).
* **Alcance prioritario:**
  * Flujos de autenticación (`AuthBloc`): Login exitoso, credenciales inválidas (401), expiración de token.
  * Gestión de finanzas y caja (`FinanzasBloc`): Registro de movimientos, cálculo reactivo de balances.
  * Lógica de carrito y ventas: Agregado/eliminación de items, validación de stock local antes de enviar la orden.
* **Directriz de diseño:** Todos los servicios inyectados (`DioClient`, repositorios) deben ser simulados con `mocktail` (`class MockVentaRepository extends Mock implements VentaRepository {}`).

---

### Nivel 2: Pruebas Unitarias (Modelos, Parsers y Servicios)
* **Directorio:** `test/models/` y `test/services/`
* **Tecnologías:** `flutter_test`, `mocktail`.
* **Propósito:** Garantizar que la serialización (`fromJson`, `toJson`), la inmutabilidad (`copyWith`, `Equatable`), las reglas de dominio encapsuladas y los clientes HTTP operen de manera aislada y pura.
* **Alcance prioritario:**
  * Modelos de venta y stock: [`CartItem`](file:///C:/Users/chesa/SGI-U/frontend/lib/models/cart_item.dart), [`CompletedSale`](file:///C:/Users/chesa/SGI-U/frontend/lib/models/completed_sale.dart), [`Product`](file:///C:/Users/chesa/SGI-U/frontend/lib/models/product.dart).
  * Consumo de KPIs: [`dashboard_models.dart`](file:///C:/Users/chesa/SGI-U/frontend/lib/models/dashboard_models.dart).
  * Contratos de servicios HTTP: Intercepción de cabeceras JWT, manejo de timeout y traducción de códigos de error (400, 401, 404, 500).

---

### Nivel 3: Pruebas de Widgets (Componentes Visuales y Diálogos)
* **Directorio:** `test/widgets/`
* **Tecnologías:** `flutter_test`, `WidgetTester`.
* **Propósito:** Validar la presentación y comportamiento de componentes visuales aislados sin interactuar con un backend real ni renderizar la aplicación completa.
* **Alcance prioritario:**
  * Estados de deshabilitación: Botón de confirmación de venta deshabilitado cuando el carrito está vacío o el stock es insuficiente.
  * Diálogos modales y alertas: Confirmación de borrado, feedback de error ante respuestas de red.
  * Renderizado condicional: Banderas de stock crítico en listas de productos y badges de alerta.
* **Directriz de diseño:** Envolver siempre los widgets en `MaterialApp` o `Scaffold` con un mock del BLoC correspondiente provisto vía `BlocProvider.value`.

---

### Nivel 4: Pruebas End-to-End e Integración Transaccional
* **Directorio:** `integration_test/` (en la raíz del proyecto frontend)
* **Tecnologías:** `integration_test`, `flutter_test`.
* **Propósito:** Ejecutar la aplicación sobre un dispositivo o emulador real/headless simulando la experiencia del usuario final.
* **Alcance prioritario:**
  * Flujo integral de checkout: Inicio de sesión -> Navegación al catálogo -> Selección de productos -> Ajuste de cantidades -> Confirmación de venta -> Verificación del comprobante y actualización del balance financiero.
  * Recuperación de errores de red y resiliencia ante reconexión.

---

## 3. Convenciones de Nomenclatura y Ejecución
* Los archivos de prueba deben terminar con el sufijo `_test.dart` (ej: `cart_item_test.dart`, `finanzas_bloc_test.dart`).
* **Comandos de ejecución:**
  * Ejecutar suite unitaria y de widgets:
    ```bash
    flutter test
    ```
  * Ejecutar con cobertura:
    ```bash
    flutter test --coverage
    ```
  * Ejecutar pruebas E2E:
    ```bash
    flutter test integration_test/app_flow_test.dart
    ```
