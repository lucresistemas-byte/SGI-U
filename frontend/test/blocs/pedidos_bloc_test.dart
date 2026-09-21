import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_event.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_state.dart';
import 'package:sgi_u_frontend/models/pedido.dart';
import 'package:sgi_u_frontend/models/pedido_abono.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  group('PedidosBloc - Máquina de Estados y Abonos (Tarea 8.3)', () {
    late MockApiService mockApiService;
    late PedidosBloc pedidosBloc;

    const pedidoInicial = Pedido(
      id: 10,
      clienteNombre: 'Gonzalo Ramírez',
      clienteTelefono: '343-4567890',
      descripcion: 'Caja de alfajores artesanales surtidos',
      montoTotal: 5000.0,
      senia: 0.0,
      saldo: 5000.0,
      estado: 'PENDIENTE',
      abonos: [],
    );

    const pedidoAbonado2000 = Pedido(
      id: 10,
      clienteNombre: 'Gonzalo Ramírez',
      clienteTelefono: '343-4567890',
      descripcion: 'Caja de alfajores artesanales surtidos',
      montoTotal: 5000.0,
      senia: 2000.0,
      saldo: 3000.0,
      estado: 'PENDIENTE',
      abonos: [
        PedidoAbono(id: 1, monto: 2000.0, metodoPago: 'EFECTIVO'),
      ],
    );

    const pedidoSaldadoTotal = Pedido(
      id: 10,
      clienteNombre: 'Gonzalo Ramírez',
      clienteTelefono: '343-4567890',
      descripcion: 'Caja de alfajores artesanales surtidos',
      montoTotal: 5000.0,
      senia: 2000.0,
      saldo: 0.0,
      estado: 'PAGADO',
      abonos: const [
        PedidoAbono(id: 1, monto: 2000.0, metodoPago: 'EFECTIVO'),
        PedidoAbono(id: 2, monto: 3000.0, metodoPago: 'TRANSFERENCIA'),
      ],
    );

    setUp(() {
      mockApiService = MockApiService();
      pedidosBloc = PedidosBloc(apiService: mockApiService);
    });

    tearDown(() {
      pedidosBloc.close();
    });

    test('Modelo Pedido calcula correctamente estado inicial Pendiente', () {
      expect(pedidoInicial.montoTotal, equals(5000.0));
      expect(pedidoInicial.saldo, equals(5000.0));
      expect(pedidoInicial.estadoCalculado, equals('Pendiente'));
    });

    test('Modelo Pedido con total \$5000 y abono de \$2000 tiene estado Parcialmente Pagado y saldo \$3000', () {
      expect(pedidoAbonado2000.montoTotal, equals(5000.0));
      expect(pedidoAbonado2000.saldo, equals(3000.0));
      expect(pedidoAbonado2000.totalPagado, equals(2000.0));
      expect(pedidoAbonado2000.estadoCalculado, equals('Parcialmente Pagado'));
    });

    test('Modelo Pedido con saldo 0 tiene estado Pagado', () {
      expect(pedidoSaldadoTotal.saldo, equals(0.0));
      expect(pedidoSaldadoTotal.totalPagado, equals(5000.0));
      expect(pedidoSaldadoTotal.estadoCalculado, equals('Pagado'));
    });

    blocTest<PedidosBloc, PedidosState>(
      'Validar máquina de estados: si el total es \$5000 y se registra un abono de \$2000, el pedido pasa a "Parcialmente Pagado" con saldo \$3000',
      build: () {
        when(() => mockApiService.abonarPedido(
              10,
              monto: 2000.0,
              metodoPago: any(named: 'metodoPago'),
              nota: any(named: 'nota'),
            )).thenAnswer((_) async => pedidoAbonado2000);
        return pedidosBloc;
      },
      seed: () => PedidosState(
        pedidos: [pedidoInicial],
        filteredPedidos: [pedidoInicial],
      ),
      act: (bloc) => bloc.add(const RegistrarAbonoEvent(
        pedidoId: 10,
        monto: 2000.0,
        metodoPago: 'EFECTIVO',
      )),
      expect: () => [
        isA<PedidosState>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<PedidosState>()
            .having((s) => s.isSubmitting, 'isSubmitting', false)
            .having((s) => s.pedidos.first.saldo, 'saldo pendiente', 3000.0)
            .having((s) => s.pedidos.first.estadoCalculado, 'estado calculado',
                'Parcialmente Pagado')
            .having((s) => s.successMessage, 'successMessage',
                'Abono registrado correctamente'),
      ],
      verify: (_) {
        verify(() => mockApiService.abonarPedido(
              10,
              monto: 2000.0,
              metodoPago: any(named: 'metodoPago'),
              nota: any(named: 'nota'),
            )).called(1);
      },
    );

    blocTest<PedidosBloc, PedidosState>(
      'BuscarPedidos filtra instantáneamente por nombre o por teléfono',
      build: () => pedidosBloc,
      seed: () => PedidosState(
        pedidos: [
          pedidoInicial,
          const Pedido(
            id: 20,
            clienteNombre: 'Silvia Fernández',
            clienteTelefono: '343-9876543',
            descripcion: 'Torta temática',
            montoTotal: 8000.0,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const BuscarPedidos('9876543')),
      expect: () => [
        isA<PedidosState>()
            .having((s) => s.filteredPedidos.length, 'filtrados por teléfono', 1)
            .having((s) => s.filteredPedidos.first.clienteNombre, 'cliente',
                'Silvia Fernández'),
      ],
    );
  });
}
