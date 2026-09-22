import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_event.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_state.dart';
import 'package:sgi_u_frontend/models/pedido.dart';
import 'package:sgi_u_frontend/screens/pedidos_screen.dart';

class MockPedidosBloc extends MockBloc<PedidosEvent, PedidosState>
    implements PedidosBloc {}

class FakePedidosEvent extends Fake implements PedidosEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePedidosEvent());
    registerFallbackValue(const RegistrarAbonoEvent(
      pedidoId: 1,
      monto: 100.0,
    ));
  });

  group('PedidosScreen - Búsqueda, Selección y Registro de Abono (Tarea 8.3)', () {
    late MockPedidosBloc mockPedidosBloc;

    const pedidoGonzalo = Pedido(
      id: 10,
      clienteNombre: 'Gonzalo Ramírez',
      clienteTelefono: '343-4567890',
      descripcion: 'Torta Selva Negra',
      montoTotal: 5000.0,
      senia: 2000.0,
      saldo: 3000.0,
      estado: 'PENDIENTE',
    );

    const pedidoSilvia = Pedido(
      id: 20,
      clienteNombre: 'Silvia Fernández',
      clienteTelefono: '343-9876543',
      descripcion: 'Caja de alfajores',
      montoTotal: 3000.0,
      senia: 0.0,
      saldo: 3000.0,
      estado: 'PENDIENTE',
    );

    setUp(() {
      mockPedidosBloc = MockPedidosBloc();
    });

    tearDown(() {
      mockPedidosBloc.close();
    });

    testWidgets(
      'Simular búsqueda de un cliente, seleccionarlo de la lista y registrar el abono',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stateController = StreamController<PedidosState>.broadcast();
        addTearDown(stateController.close);

        const initialState = PedidosState(
          pedidos: [pedidoGonzalo, pedidoSilvia],
          filteredPedidos: [pedidoGonzalo, pedidoSilvia],
        );

        when(() => mockPedidosBloc.state).thenReturn(initialState);
        whenListen(
          mockPedidosBloc,
          stateController.stream,
          initialState: initialState,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PedidosScreen(pedidosBloc: mockPedidosBloc),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Inicialmente se ven ambos clientes
        expect(find.text('Gonzalo Ramírez'), findsOneWidget);
        expect(find.text('Silvia Fernández'), findsOneWidget);

        // 2. Simular búsqueda por nombre de cliente
        final buscarInput = find.byKey(const Key('buscar_pedido_input'));
        expect(buscarInput, findsOneWidget);
        await tester.enterText(buscarInput, 'Gonzalo');
        await tester.pump();

        verify(() => mockPedidosBloc.add(const BuscarPedidos('Gonzalo'))).called(1);

        // BLoC emite estado filtrado con solo Gonzalo
        final filteredState = initialState.copyWith(
          filteredPedidos: [pedidoGonzalo],
          searchQuery: 'Gonzalo',
        );
        when(() => mockPedidosBloc.state).thenReturn(filteredState);
        stateController.add(filteredState);
        await tester.pumpAndSettle();

        expect(find.text('Gonzalo Ramírez'), findsOneWidget);
        expect(find.text('Silvia Fernández'), findsNothing);

        // 3. Seleccionar de la lista y registrar abono
        final abonarBtnFinder = find.byKey(const Key('abonar_pedido_10'));
        expect(abonarBtnFinder, findsOneWidget);
        await tester.ensureVisible(abonarBtnFinder);
        await tester.tap(abonarBtnFinder);
        await tester.pumpAndSettle();

        // Diálogo de abono abierto
        expect(find.text('Registrar Abono: Gonzalo Ramírez'), findsOneWidget);

        // 4. Ingresar monto del abono (por ejemplo $1500)
        final montoInput = find.byKey(const Key('abono_monto_input'));
        expect(montoInput, findsOneWidget);
        await tester.enterText(montoInput, '1500');
        await tester.pump();

        // 5. Confirmar abono
        final confirmarBtn = find.byKey(const Key('confirmar_abono_button'));
        expect(confirmarBtn, findsOneWidget);
        await tester.tap(confirmarBtn);
        await tester.pumpAndSettle();

        // 6. Verificar que se disparó el evento RegistrarAbonoEvent con los datos correctos
        verify(() => mockPedidosBloc.add(any(
              that: isA<RegistrarAbonoEvent>()
                  .having((e) => e.pedidoId, 'pedidoId', 10)
                  .having((e) => e.monto, 'monto', 1500.0),
            ))).called(1);
      },
    );
  });
}
