# Estrategia de Testing — SGI-U Frontend

Estrategia de calidad en 4 niveles, espejada en la estructura de `test/` e `integration_test/`.
Todas las suites son **deterministas**: sin red, sin backend real, sin relojes dependientes.

## Nivel 1 — Pruebas de estado (BLoC tests)

Cubren la lógica de negocio de los BLoCs (transiciones de estado y mensajes).

- Herramientas: `bloc_test` (`blocTest<Bloc, State>`) + `mocktail` (mocks de servicios/repositorios).
- Ubicación: `test/blocs/`.
- Archivos: `auth_bloc_test.dart`, `pos_bloc_test.dart`, `finanzas_bloc_test.dart` (y variantes de stock/sesión).

## Nivel 2 — Pruebas unitarias de modelos

Cubren parseo `fromJson`, valores por defecto y contratos `Equatable`.

- Herramientas: `flutter_test` puro.
- Ubicación: `test/models/`.
- Archivos: `product_test.dart`, `cart_item_test.dart`, `completed_sale_test.dart`.

> Nota: el spec original listaba `pago_linea_test.dart`, pero el modelo `PagoLinea` **no existe**
> en `lib/` (el selector de pago usa `selectedPaymentMethod` con radios fijos). Se omitió el archivo
> y se documenta la desviación aquí a propósito.

## Nivel 3 — Pruebas de widgets

Cubren renderizado, validación, eventos disparados por interacción y mensajes de éxito/error.

- Herramientas: `flutter_test` (`testWidgets`) + `BlocProvider.value` con un BLoC real alimentado por
  fakes que implementan `PosApi`/`ApiService` (patrón del repo) o mocks `mocktail`.
- Ubicación: `test/widgets/`.
- Archivos: `payment_method_selector_test.dart`, `producto_form_dialog_test.dart` (+ variante de stock),
  `movimiento_form_dialog_test.dart`, `cart_table_test.dart`.

## Nivel 4 — Tests end-to-end (integration)

Validan el flujo real de la UI sobre las pantallas reales (login → catálogo → POS → venta → balance)
con servicios inyectados (fakes), sin backend.

- Herramientas: `integration_test` (SDK) + `IntegrationTestWidgetsFlutterBinding`.
- Ubicación: `integration_test/`.
- Archivo: `flujo_venta_test.dart`.

> `http_mock_adapter` no se enchufa al `ApiService` real (singleton con `Dio` privado); por eso el
> flujo de integración usa fakes/mocks inyectados en los BLoCs.

## Convenciones

- Nombres de archivo: `<sujeto>_test.dart` (sufijo obligatorio).
- Tests de BLoC: `blocTest<Bloc, State>` con mocks `mocktail`.
- Tests de servicios sin red: solo miembros puros/testables (predicado de sesión, setters de URL/token).
- Un fallo producido por un bug real del código se documenta en el propio test con `/* TODO: ... */`
  **sin** modificar código de producción.

## Advertencias conocidas (lecciones de implementación)

- Dentro de `testWidgets` el cuerpo corre en una zona `FakeAsync`: **no** se debe esperar un evento de
  BLoC con `bloc.stream.firstWhere(...)` directamente (cuelga el test). Se siembra el BLoC con
  `tester.pump()` hasta que `bloc.state` alcance la condición.
- Si un test amplía el viewport para evitar un overflow, se documenta con `/* TODO */` porque puede
  estar enmascarando un problema real de layout (p. ej. `MovimientoFormDialog` con mensaje de error).
- `PosBloc._onAddToCart` **suma** cantidades para un producto ya presente (1 + 2 = 3): los tests de
  carrito esperan el total acumulado, no el valor enviado.

## Comandos

```bash
flutter analyze --no-pub      # 0 errores/warnings (infos preexistentes toleradas)
flutter test                  # toda la suite de test/ (116 tests)
flutter test integration_test/flujo_venta_test.dart -d windows # e2e (probado en dispositivo Windows)
```