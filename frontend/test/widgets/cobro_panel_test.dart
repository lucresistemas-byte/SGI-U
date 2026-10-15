import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/screens/pos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockPosApi extends Mock implements PosApi {}

/// Parte 3: cobro del POS con una o varias líneas de pago.
void main() {
  const efectivo = MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1);
  const tarjeta = MetodoPago(id: 3, nombre: 'Tarjeta', orden: 2);

  late _MockPosApi api;
  late PosBloc bloc;

  /// Panel derecho con Café a $150 x 2 en el carrito (total $300).
  Future<void> montar(WidgetTester t, {List<MetodoPago> metodos = const [efectivo, tarjeta]}) async {
    t.view.physicalSize = const Size(500, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    api = _MockPosApi();
    when(() => api.getProducts()).thenAnswer((_) async => [
          {'codigo': 'P1', 'nombre': 'Café', 'precioUnitario': 150.0, 'stockActual': 10, 'activo': true},
        ]);
    when(() => api.createSale(any())).thenAnswer((_) async {});
    bloc = PosBloc(apiService: api, cargarMetodosPago: () async => metodos);
    addTearDown(bloc.close);
    await t.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const Scaffold(body: RightPanel()),
      ),
    ));
    bloc.add(const LoadProducts());
    await t.pumpAndSettle();
    bloc.add(const AddToCart('P1', 2));
    await t.pumpAndSettle();
  }

  ElevatedButton confirmar(WidgetTester t) =>
      t.widget<ElevatedButton>(find.byKey(const Key('confirmar_cobro_button')));

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('Confirmar cobro se habilita recién cuando los pagos cubren el total', (t) async {
    await montar(t);
    expect(confirmar(t).onPressed, isNull);
    expect(find.text('Falta: \$ 300,00'), findsOneWidget);

    // Camino rápido: un toque en Efectivo paga todo.
    await tocar(t, find.byKey(const Key('pagar_restante_1')));

    expect(confirmar(t).onPressed, isNotNull);
    expect(find.byKey(const Key('pago_falta')), findsNothing);
    await tocar(t, find.byKey(const Key('confirmar_cobro_button')));
    verify(() => api.createSale(any())).called(1);
  });

  testWidgets('mixto: tarjeta por una parte y efectivo por el resto', (t) async {
    await montar(t);

    await t.enterText(find.byKey(const Key('pago_monto_input')), '100');
    await tocar(t, find.byKey(const Key('pago_metodo_dropdown')));
    await tocar(t, find.text('Tarjeta').last);
    await tocar(t, find.byKey(const Key('agregar_pago_button')));

    expect(find.text('Falta: \$ 200,00'), findsOneWidget);
    expect(confirmar(t).onPressed, isNull);

    await tocar(t, find.byKey(const Key('pagar_restante_1')));
    expect(find.byKey(const Key('linea_pago_0')), findsOneWidget);
    expect(find.byKey(const Key('linea_pago_1')), findsOneWidget);
    expect(confirmar(t).onPressed, isNotNull);

    await tocar(t, find.byKey(const Key('confirmar_cobro_button')));
    final datos = verify(() => api.createSale(captureAny())).captured.single as Map<String, dynamic>;
    expect(datos['pagos'], [
      {'metodoPagoId': 3, 'monto': 100.0},
      {'metodoPagoId': 1, 'monto': 200.0},
    ]);
  });

  testWidgets('efectivo de más muestra el vuelto', (t) async {
    await montar(t);

    await t.enterText(find.byKey(const Key('pago_monto_input')), '500');
    await tocar(t, find.byKey(const Key('agregar_pago_button')));

    expect(find.text('Vuelto: \$ 200,00'), findsOneWidget);
    expect(confirmar(t).onPressed, isNotNull);
  });

  testWidgets('solo se ofrecen los métodos activos', (t) async {
    // La lista llega de GET /api/metodos-pago (solo activos): Tarjeta está
    // desactivada y no aparece.
    await montar(t, metodos: const [efectivo]);

    expect(find.byKey(const Key('pagar_restante_1')), findsOneWidget);
    expect(find.byKey(const Key('pagar_restante_3')), findsNothing);
    expect(find.text('Tarjeta'), findsNothing);
  });

  testWidgets('sin carrito no se puede cargar pagos ni confirmar', (t) async {
    await montar(t);
    bloc.add(const RemoveFromCart('P1'));
    await t.pumpAndSettle();

    expect(t.widget<OutlinedButton>(find.byKey(const Key('pagar_restante_1'))).onPressed, isNull);
    expect(confirmar(t).onPressed, isNull);
  });
}
