import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_event.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_state.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/models/pedido.dart';
import 'package:sgi_u_frontend/screens/pedidos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockPedidosBloc extends MockBloc<PedidosEvent, PedidosState> implements PedidosBloc {}

class _MockApi extends Mock implements ApiService {}

class _FakeEvent extends Fake implements PedidosEvent {}

/// Parte 2: la seña y los pagos de pedidos ofrecen los métodos activos de
/// Configuración y envían su id.
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  const metodos = [
    MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1),
    MetodoPago(id: 4, nombre: 'Transferencia', orden: 2),
  ];
  const pendiente = Pedido(
    id: 3,
    clienteNombre: 'Ana Pérez',
    clienteTelefono: '1155550001',
    descripcion: 'Torta chocolate',
    montoTotal: 9000,
    senia: 3000,
  );

  Future<_MockPedidosBloc> montar(WidgetTester t) async {
    t.view.physicalSize = const Size(1800, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final bloc = _MockPedidosBloc();
    whenListen(bloc, const Stream<PedidosState>.empty(),
        initialState: const PedidosState(pedidos: [pendiente], filteredPedidos: [pendiente], metodosPago: metodos));
    await t.pumpWidget(MaterialApp(home: PedidosScreen(pedidosBloc: bloc)));
    await t.pump();
    return bloc;
  }

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('la seña ofrece los métodos activos y envía el id elegido', (t) async {
    final bloc = await montar(t);
    await tocar(t, find.byKey(const Key('nuevo_pedido_button')));

    await t.enterText(find.byKey(const Key('pedido_cliente_input')), 'Laura');
    await t.enterText(find.byKey(const Key('pedido_telefono_input')), '1144443333');
    await t.enterText(find.byKey(const Key('pedido_descripcion_input')), 'Torta');
    await t.enterText(find.byKey(const Key('pedido_monto_total_input')), '10000');
    await t.enterText(find.byKey(const Key('pedido_senia_input')), '2000');

    await tocar(t, find.byKey(const Key('pedido_metodo_pago_dropdown')));
    // Solo los activos (no los de antes: Débito/Crédito).
    expect(find.text('Débito'), findsNothing);
    await tocar(t, find.text('Transferencia').last);
    await tocar(t, find.text('Guardar Pedido'));

    final evento = verify(() => bloc.add(captureAny(that: isA<CrearPedidoEvent>()))).captured.single
        as CrearPedidoEvent;
    expect(evento.data['metodoPagoSeniaId'], 4);
  });

  testWidgets('el abono usa Efectivo por defecto', (t) async {
    final bloc = await montar(t);
    await tocar(t, find.byKey(const Key('abonar_pedido_3')));
    await tocar(t, find.byKey(const Key('confirmar_abono_button')));

    final evento = verify(() => bloc.add(captureAny(that: isA<RegistrarAbonoEvent>()))).captured.single
        as RegistrarAbonoEvent;
    expect(evento.metodoPagoId, 1);
  });

  blocTest<PedidosBloc, PedidosState>(
    'al cargar los pedidos trae los métodos activos',
    build: () {
      final api = _MockApi();
      when(() => api.getPedidos(query: any(named: 'query'))).thenAnswer((_) async => const [pendiente]);
      when(() => api.getMetodosPago()).thenAnswer((_) async => metodos);
      return PedidosBloc(apiService: api);
    },
    act: (b) => b.add(const CargarPedidos()),
    expect: () => [
      isA<PedidosState>().having((s) => s.isLoading, 'cargando', true),
      isA<PedidosState>().having((s) => s.metodosPago, 'métodos', metodos),
    ],
  );
}
