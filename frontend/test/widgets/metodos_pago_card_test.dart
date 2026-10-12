import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/configuracion/metodos_pago_card.dart';

class _MockApi extends Mock implements ApiService {}

/// Parte 2: Configuración → Métodos de pago.
void main() {
  late _MockApi api;
  const efectivo = MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1);
  const mp = MetodoPago(id: 2, nombre: 'Mercado Pago', orden: 2);
  const viejo = MetodoPago(id: 5, nombre: 'Cheque', activo: false, orden: 3);

  setUp(() {
    api = _MockApi();
    when(() => api.getMetodosPago(incluirInactivos: true)).thenAnswer((_) async => const [efectivo, mp, viejo]);
    when(() => api.crearMetodoPago(any())).thenAnswer((_) async => const MetodoPago(id: 6, nombre: 'Cuenta DNI'));
    when(() => api.renombrarMetodoPago(any(), any())).thenAnswer((_) async => mp);
    when(() => api.cambiarEstadoMetodoPago(any(), activo: any(named: 'activo'))).thenAnswer((_) async => mp);
    when(() => api.reordenarMetodosPago(any())).thenAnswer((_) async => const [mp, efectivo, viejo]);
  });

  Future<void> montar(WidgetTester t) async {
    t.view.physicalSize = const Size(1200, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MetodosPagoCard(apiService: api)))));
    await t.pumpAndSettle();
  }

  testWidgets('Efectivo es fijo: no se puede renombrar ni desactivar', (t) async {
    await montar(t);

    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Fijo: no se renombra ni se desactiva'), findsOneWidget);
    expect(find.byKey(const Key('metodo_pago_renombrar_1')), findsNothing);
    expect(find.byKey(const Key('metodo_pago_estado_1')), findsNothing);
    expect(find.byKey(const Key('metodo_pago_estado_2')), findsOneWidget);
    // Los inactivos se listan (para reactivarlos).
    expect(find.text('Cheque'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets('crear, renombrar, desactivar y reactivar', (t) async {
    await montar(t);

    await t.tap(find.byKey(const Key('metodo_pago_nuevo_btn')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('metodo_pago_nombre_input')), 'Cuenta DNI');
    await t.tap(find.byKey(const Key('metodo_pago_guardar_nombre')));
    await t.pumpAndSettle();
    verify(() => api.crearMetodoPago('Cuenta DNI')).called(1);

    await t.tap(find.byKey(const Key('metodo_pago_renombrar_2')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('metodo_pago_nombre_input')), 'MercadoPago QR');
    await t.tap(find.byKey(const Key('metodo_pago_guardar_nombre')));
    await t.pumpAndSettle();
    verify(() => api.renombrarMetodoPago(2, 'MercadoPago QR')).called(1);

    await t.tap(find.byKey(const Key('metodo_pago_estado_2')));
    await t.pumpAndSettle();
    verify(() => api.cambiarEstadoMetodoPago(2, activo: false)).called(1);

    await t.tap(find.byKey(const Key('metodo_pago_estado_5')));
    await t.pumpAndSettle();
    verify(() => api.cambiarEstadoMetodoPago(5, activo: true)).called(1);
  });

  testWidgets('reordenar envía todos los métodos en el orden nuevo', (t) async {
    await montar(t);

    expect(t.widget<IconButton>(find.byKey(const Key('metodo_pago_subir_1'))).onPressed, isNull);
    await t.tap(find.byKey(const Key('metodo_pago_subir_2')));
    await t.pumpAndSettle();

    verify(() => api.reordenarMetodosPago([2, 1, 5])).called(1);
  });
}
