import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_event.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_state.dart';
import 'package:sgi_u_frontend/models/pedido.dart';
import 'package:sgi_u_frontend/screens/pedidos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockPedidosBloc extends MockBloc<PedidosEvent, PedidosState>
    implements PedidosBloc {}

class _MockApi extends Mock implements ApiService {}

class _FakeEvent extends Fake implements PedidosEvent {}

/// Pedidos: E-14 (botón cancelar con confirmación), E-19 (búsqueda por
/// dígitos del teléfono) y E-20 (fecha y hora de entrega en la tabla).
void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  final pendiente = Pedido(
    id: 3,
    clienteNombre: 'Ana Pérez',
    clienteTelefono: '11-5555-0001',
    descripcion: 'Torta chocolate',
    montoTotal: 9000,
    senia: 3000,
    fechaEntrega: DateTime(2026, 10, 20, 15, 30),
  );
  const cancelado = Pedido(
    id: 4,
    clienteNombre: 'Bruno',
    clienteTelefono: '(011) 4444 2222',
    descripcion: 'Budín',
    montoTotal: 6000,
    senia: 2000,
    estado: 'CANCELADO',
  );

  group('pantalla', () {
    late _MockPedidosBloc bloc;

    Future<void> montar(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      bloc = _MockPedidosBloc();
      final estado = PedidosState(pedidos: [pendiente, cancelado], filteredPedidos: [pendiente, cancelado]);
      whenListen(bloc, const Stream<PedidosState>.empty(), initialState: estado);
      await tester.pumpWidget(MaterialApp(home: PedidosScreen(pedidosBloc: bloc)));
      await tester.pump();
    }

    Future<void> tocar(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('la tabla muestra fecha y hora de entrega', (tester) async {
      await montar(tester);

      expect(find.text('Entrega'), findsOneWidget);
      expect(find.text('20/10/2026 15:30'), findsOneWidget);
    });

    testWidgets('cancelar pide confirmación; el cancelado no ofrece cancelar ni abonar',
        (tester) async {
      await montar(tester);

      expect(find.byKey(const Key('cancelar_pedido_4')), findsNothing);
      expect(find.byKey(const Key('abonar_pedido_4')), findsNothing);
      expect(find.text('Cancelado'), findsWidgets);

      await tocar(tester, find.byKey(const Key('cancelar_pedido_3')));
      expect(find.textContaining('No se puede deshacer'), findsOneWidget);
      await tocar(tester, find.text('Volver'));
      verifyNever(() => bloc.add(any(that: isA<CancelarPedidoEvent>())));

      await tocar(tester, find.byKey(const Key('cancelar_pedido_3')));
      await tocar(tester, find.widgetWithText(ElevatedButton, 'Cancelar pedido'));
      verify(() => bloc.add(const CancelarPedidoEvent(3))).called(1);
    });
  });

  group('búsqueda local', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
      when(() => api.getPedidos(query: any(named: 'query')))
          .thenAnswer((_) async => [pendiente, cancelado]);
    });

    blocTest<PedidosBloc, PedidosState>(
      'el teléfono se compara solo por dígitos',
      build: () => PedidosBloc(apiService: api),
      seed: () => PedidosState(pedidos: [pendiente, cancelado], filteredPedidos: [pendiente, cancelado]),
      act: (b) => b
        ..add(const BuscarPedidos('1155550001'))
        ..add(const BuscarPedidos('4444-2222')),
      expect: () => [
        isA<PedidosState>().having(
            (s) => s.filteredPedidos.map((p) => p.id), 'ids', [3]),
        isA<PedidosState>().having(
            (s) => s.filteredPedidos.map((p) => p.id), 'ids', [4]),
      ],
    );
  });
}
