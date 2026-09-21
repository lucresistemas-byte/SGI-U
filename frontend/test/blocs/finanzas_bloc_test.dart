import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_event.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_state.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

final _resumenEspectado = {
  'ingresosHoy': 1000.0,
  'egresosHoy': 200.0,
  'saldoActual': 800.0,
};

final _balanceDia = {
  'totalIngresos': 1000.0,
  'totalEgresos': 200.0,
};
final _balanceMes = {
  'margenNeto': 800.0,
};

void main() {
  group('FinanzasBloc - CargarResumen (N1)', () {
    late MockApiService api;

    blocTest<FinanzasBloc, FinanzasState>(
      'CargarResumen exitoso emite ResumenLoaded con los datos del servicio',
      build: () {
        api = MockApiService();
        when(() => api.getResumenFinanciero())
            .thenAnswer((_) async => Map.of(_resumenEspectado));
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(const CargarResumen()),
      expect: () => [
        isA<ResumenLoading>(),
        isA<ResumenLoaded>().having((s) => s.resumen, 'resumen', _resumenEspectado),
      ],
    );

    blocTest<FinanzasBloc, FinanzasState>(
      'CargarResumen con error del servicio emite ResumenLoaded con ceros',
      build: () {
        api = MockApiService();
        when(() => api.getResumenFinanciero())
            .thenThrow(Exception('Error de red'));
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(const CargarResumen()),
      expect: () => [
        isA<ResumenLoading>(),
        isA<ResumenLoaded>().having(
            (s) => s.resumen,
            'resumen en cero',
            {'ingresosHoy': 0.0, 'egresosHoy': 0.0, 'saldoActual': 0.0}),
      ],
    );
  });

  group('FinanzasBloc - CargarMovimientos (N1)', () {
    late MockApiService api;

    setUp(() {
      api = MockApiService();
    });

    blocTest<FinanzasBloc, FinanzasState>(
      'CargarMovimientos exitoso emite MovimientosLoaded con lista y resumen',
      build: () {
        when(() => api.getMovimientos(
                pagina: any(named: 'pagina'), limite: any(named: 'limite')))
            .thenAnswer(
                (_) async => [{'id': 1, 'tipo': 'INGRESO'}]);
        when(() => api.getBalance(any(), any())).thenAnswer((invocation) async {
          final inicio = invocation.positionalArguments[0] as DateTime;
          // dataHoy = getBalance(hoy, hoy) y dataMes = getBalance(inicioMes, hoy)
          return inicio.day == 1 ? Map.of(_balanceMes) : Map.of(_balanceDia);
        });
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(const CargarMovimientos()),
      expect: () => [
        isA<MovimientosLoading>(),
        isA<MovimientosLoaded>()
            .having((s) => s.movimientos, 'movimientos', hasLength(1))
            .having((s) => s.resumen, 'resumen', _resumenEspectado),
      ],
    );

    blocTest<FinanzasBloc, FinanzasState>(
      'CargarMovimientos con error del servicio emite MovimientosError',
      build: () {
        when(() => api.getMovimientos(
                pagina: any(named: 'pagina'), limite: any(named: 'limite')))
            .thenThrow(Exception('Error de red'));
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(const CargarMovimientos()),
      expect: () => [
        isA<MovimientosLoading>(),
        isA<MovimientosError>().having(
            (s) => s.message, 'message', contains('Error de red')),
      ],
    );
  });

  group('FinanzasBloc - CrearMovimiento (N1)', () {
    late MockApiService api;

    blocTest<FinanzasBloc, FinanzasState>(
      'CrearMovimiento exitoso emite OperacionExitosa y recarga resumen y movimientos',
      build: () {
        api = MockApiService();
        when(() => api.createMovimiento(any())).thenAnswer((_) async {});
        when(() => api.getResumenFinanciero())
            .thenAnswer((_) async => Map.of(_resumenEspectado));
        when(() => api.getMovimientos(
                pagina: any(named: 'pagina'), limite: any(named: 'limite')))
            .thenAnswer(
                (_) async => [{'id': 9, 'tipo': 'INGRESO'}]);
        when(() => api.getBalance(any(), any())).thenAnswer((invocation) async {
          final inicio = invocation.positionalArguments[0] as DateTime;
          return inicio.day == 1 ? Map.of(_balanceMes) : Map.of(_balanceDia);
        });
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(const CrearMovimiento(
        tipo: 'Ingreso',
        monto: 1000,
        metodoPago: 'Efectivo',
        categoria: 'Venta',
        descripcion: 'Venta diaria',
      )),
      expect: () => [
        isA<OperacionExitosa>().having(
            (s) => s.mensaje, 'mensaje', 'Movimiento registrado correctamente'),
        isA<ResumenLoading>(),
        isA<ResumenLoaded>(),
        isA<MovimientosLoading>(),
        isA<MovimientosLoaded>(),
      ],
      verify: (_) => verify(() => api.createMovimiento(any())).called(1),
    );

    blocTest<FinanzasBloc, FinanzasState>(
      'CrearMovimiento con error del backend emite MovimientosError',
      build: () {
        api = MockApiService();
        when(() => api.createMovimiento(any()))
            .thenThrow(Exception('Datos inválidos'));
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(const CrearMovimiento(
        tipo: 'Egreso',
        monto: 500,
        metodoPago: 'Efectivo',
        categoria: 'Gasto',
        descripcion: 'Compra de insumos',
      )),
      expect: () => [
        isA<MovimientosError>().having(
            (s) => s.message, 'message', contains('Datos inválidos')),
      ],
    );
  });

  group('FinanzasBloc - CargarBalance (N1)', () {
    late MockApiService api;

    final desde = DateTime(2026, 9, 1);
    final hasta = DateTime(2026, 9, 21);

    blocTest<FinanzasBloc, FinanzasState>(
      'CargarBalance exitoso emite BalanceLoaded con el mapa del backend',
      build: () {
        api = MockApiService();
        when(() => api.getBalance(any(), any()))
            .thenAnswer((_) async => Map.of(_balanceMes));
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(CargarBalance(desde, hasta)),
      expect: () => [
        isA<BalanceLoading>(),
        isA<BalanceLoaded>().having((s) => s.balance, 'balance', _balanceMes),
      ],
    );

    blocTest<FinanzasBloc, FinanzasState>(
      'CargarBalance con error del servicio emite MovimientosError',
      build: () {
        api = MockApiService();
        when(() => api.getBalance(any(), any()))
            .thenThrow(Exception('Error de red'));
        return FinanzasBloc(apiService: api);
      },
      act: (bloc) => bloc.add(CargarBalance(desde, hasta)),
      expect: () => [
        isA<BalanceLoading>(),
        isA<MovimientosError>().having(
            (s) => s.message, 'message', contains('Error de red')),
      ],
    );
  });
}