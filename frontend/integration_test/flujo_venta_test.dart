import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sgi_u_frontend/main.dart';
import 'package:sgi_u_frontend/navigation/app_shell.dart';
import 'package:sgi_u_frontend/screens/login_screen.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/services/storage_service.dart';
import 'package:sgi_u_frontend/widgets/app_dialog.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'E2E Flujo Crítico de Negocio: Login -> Navegación POS -> Agregar Elaborado -> Pago Mixto -> Confirmar Venta',
      (WidgetTester tester) async {
    // 1. Configuración de pantalla de escritorio (1440x900)
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Asegurar estado limpio de autenticación contra el backend local (http://localhost:3000)
    await StorageService().deleteToken();
    ApiService().clearAuthToken();

    // 2. Iniciar la aplicación completa conectada al backend real
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // -------------------------------------------------------------
    // PASO 1: Iniciar sesión exitosamente con admin / admin123
    // -------------------------------------------------------------
    expect(find.byType(LoginScreen), findsOneWidget);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    // Campo Usuario
    await tester.enterText(textFields.at(0), 'admin');
    // Campo Contraseña
    await tester.enterText(textFields.at(1), 'admin123');
    await tester.pumpAndSettle();

    // Tap en botón Iniciar sesión
    final loginBtn = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);

    // Esperar respuesta de autenticación del backend
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(AppShell).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);

    // -------------------------------------------------------------
    // PASO 2: Navegar a la sección Punto de Venta (POS)
    // -------------------------------------------------------------
    final posMenuItem = find.text('Punto de Venta');
    expect(posMenuItem, findsWidgets);
    await tester.tap(posMenuItem.first);
    await tester.pumpAndSettle();

    // Esperar a que el catálogo de productos cargue desde el backend
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('Alfajor de maicena').evaluate().isNotEmpty ||
          find.text('Tarta de coco').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.byType(PosScreen), findsOneWidget);

    // -------------------------------------------------------------
    // PASO 3: Agregar producto Elaborado al carrito (ej. Alfajor de maicena)
    // -------------------------------------------------------------
    final elaboradoFinder = find.text('Alfajor de maicena').evaluate().isNotEmpty
        ? find.text('Alfajor de maicena')
        : find.text('Tarta de coco');
    expect(elaboradoFinder, findsWidgets);

    // Tap en la tarjeta del producto para agregarlo al carrito
    await tester.tap(elaboradoFinder.first);
    await tester.pumpAndSettle();

    // Verificar que el carrito ya no está vacío
    expect(find.text('No hay productos agregados'), findsNothing);

    // -------------------------------------------------------------
    // PASO 4: Realizar Pago Mixto (Efectivo + Tarjeta / Mercado Pago)
    // -------------------------------------------------------------
    // Primer pago: ingresar monto parcial en Efectivo (ej. $200)
    final montoInput = find.byKey(const Key('pago_monto_input'));
    expect(montoInput, findsOneWidget);
    await tester.enterText(montoInput, '200');
    await tester.pumpAndSettle();

    final agregarPagoBtn = find.byKey(const Key('agregar_pago_button'));
    expect(agregarPagoBtn, findsOneWidget);
    await tester.tap(agregarPagoBtn);
    await tester.pumpAndSettle();

    // Verificar primera línea de pago
    expect(find.byKey(const Key('linea_pago_0')), findsOneWidget);
    expect(find.byKey(const Key('pago_falta')), findsOneWidget);

    // Segundo pago: cubrir el saldo restante con otro método (Tarjeta / Mercado Pago / Transferencia)
    final metodoRestanteBtn = find.byKey(const Key('pagar_restante_3')).evaluate().isNotEmpty
        ? find.byKey(const Key('pagar_restante_3')) // Tarjeta
        : find.byKey(const Key('pagar_restante_2')).evaluate().isNotEmpty
            ? find.byKey(const Key('pagar_restante_2')) // Mercado Pago
            : find.byKey(const Key('pagar_restante_4')); // Transferencia
    expect(metodoRestanteBtn, findsWidgets);

    await tester.tap(metodoRestanteBtn.first);
    await tester.pumpAndSettle();

    // Verificar que ahora existen 2 líneas de pago (Pago Mixto) y el total está cubierto
    expect(find.byKey(const Key('linea_pago_0')), findsOneWidget);
    expect(find.byKey(const Key('linea_pago_1')), findsOneWidget);
    expect(find.byKey(const Key('pago_falta')), findsNothing);

    // -------------------------------------------------------------
    // PASO 5: Confirmar la venta y verificar el diálogo de éxito
    // -------------------------------------------------------------
    final confirmarBtn = find.byKey(const Key('confirmar_cobro_button'));
    expect(confirmarBtn, findsOneWidget);
    await tester.tap(confirmarBtn);

    // Esperar a que el backend persista la venta y descuente stock recursivo
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(AppDialog).evaluate().isNotEmpty ||
          find.text('Nueva venta').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    // Validar diálogo de confirmación exitosa
    expect(find.text('Éxito'), findsOneWidget);
    expect(find.textContaining('Venta registrada correctamente'), findsOneWidget);

    // Cerrar diálogo e iniciar nueva venta
    final nuevaVentaBtn = find.text('Nueva venta');
    expect(nuevaVentaBtn, findsOneWidget);
    await tester.tap(nuevaVentaBtn);
    await tester.pumpAndSettle();

    // Validar que el carrito se reinició limpiamente
    expect(find.text('No hay productos agregados'), findsOneWidget);
  });
}
