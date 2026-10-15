import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_event.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_state.dart';
import 'package:sgi_u_frontend/navigation/ir_a_seccion.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/screens/balance_screen.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/screens/movimientos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

class _MockFinanzasBloc extends MockBloc<FinanzasEvent, FinanzasState>
    implements FinanzasBloc {}

/// Nombres claros (glosario de docs/ANALISIS_FINANZAS.md) y sin elementos
/// muertos en Inicio, Ganancias y Movimientos.
void main() {
  setUpAll(() async {
    registerFallbackValue(DateTime(2026));
    await initializeDateFormatting('es_AR', null);
  });

  void pantallaGrande(WidgetTester t) {
    t.view.physicalSize = const Size(1920, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  test('el menú dice Inicio y Ganancias', () {
    expect(Seccion.dashboard.etiqueta, 'Inicio');
    expect(Seccion.balance.etiqueta, 'Ganancias');
  });

  group('Inicio', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
      when(() => api.getMetodosPago()).thenAnswer((_) async => const []);
      when(() => api.getDashboardData(
            fechaDesde: any(named: 'fechaDesde'),
            fechaHasta: any(named: 'fechaHasta'),
            metodoPagoId: any(named: 'metodoPagoId'),
            productoId: any(named: 'productoId'),
          )).thenAnswer((_) async => <String, dynamic>{
            'kpis': <String, dynamic>{'ingresosPeriodo': 76800, 'egresosPeriodo': 123000, 'saldoNeto': -46200},
            'graficos': <String, dynamic>{},
          });
    });

    testWidgets('sin textos técnicos ni elementos sin función', (t) async {
      pantallaGrande(t);
      await t.pumpWidget(MaterialApp(home: DashboardScreen(apiService: api)));
      await t.pumpAndSettle();

      for (final viejo in [
        'SGI-U - Tablero de Control',
        'Resumen Ejecutivo',
        'Todos los productos',
        'Diario',
        'Gráfico de barras próximamente...',
        'Saldo Neto de Caja',
        'Capital disponible',
        'Ver inventario completo',
        'Ver reporte completo',
      ]) {
        expect(find.text(viejo), findsNothing, reason: viejo);
      }
      expect(find.textContaining('Margen Neto'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Caja del período'), findsOneWidget);
    });

    testWidgets('los links llevan a Productos y a Ganancias', (t) async {
      pantallaGrande(t);
      final pedidas = <Seccion>[];
      await t.pumpWidget(MaterialApp(
        home: IrASeccion(ir: pedidas.add, child: DashboardScreen(apiService: api)),
      ));
      await t.pumpAndSettle();

      await t.ensureVisible(find.byKey(const Key('inicio_ver_productos')));
      await t.tap(find.byKey(const Key('inicio_ver_productos')));
      await t.ensureVisible(find.byKey(const Key('inicio_ver_ganancias')));
      await t.tap(find.byKey(const Key('inicio_ver_ganancias')));
      expect(pedidas, [Seccion.catalogo, Seccion.balance]);
    });
  });

  testWidgets('Ganancias: categoría legible y sin paginación falsa', (t) async {
    pantallaGrande(t);
    final bloc = _MockFinanzasBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(const BalanceLoaded({
      'totalIngresos': 0.0,
      'totalEgresos': 60000.0,
      'margenNeto': -60000.0,
      'costoTotal': 0.0,
      'gananciaReal': -60000.0,
      'movimientos': [
        {
          'id': 7,
          'tipo': 'EGRESO',
          'monto': 60000.0,
          'metodoPago': 'Transferencia',
          'categoria': 'ALQUILER',
          'descripcion': 'Alquiler del local',
          'fechaHora': '2026-10-09T23:45:00.000',
        },
      ],
    }));

    await t.pumpWidget(MaterialApp(
      home: BlocProvider<FinanzasBloc>.value(value: bloc, child: const BalanceScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.text('Ganancias'), findsOneWidget);
    expect(find.text('Alquiler'), findsOneWidget);
    expect(find.text('ALQUILER'), findsNothing);
    expect(find.text('Página 1 de 1'), findsNothing);
    expect(find.text('Margen Neto'), findsNothing);
    expect(find.text('Caja del período'), findsOneWidget);
  });

  testWidgets('Movimientos: tarjetas de caja con nombre claro', (t) async {
    pantallaGrande(t);
    final bloc = _MockFinanzasBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(const MovimientosLoaded([], {}, pagina: 1, totalPaginas: 1));

    await t.pumpWidget(MaterialApp(
      home: BlocProvider<FinanzasBloc>.value(value: bloc, child: const MovimientosScreen()),
    ));
    await t.pumpAndSettle();

    expect(find.text('Saldo Actual'), findsNothing);
    expect(find.text('Caja del mes (entró − salió)'), findsOneWidget);
    expect(find.text('Caja de hoy (entró − salió)'), findsOneWidget);
  });

  group('egresos sin costo ni ganancia', () {
    const alquiler = {
      'id': 7,
      'tipo': 'EGRESO',
      'monto': 60000.0,
      'costo': null,
      'ganancia': null,
      'metodoPago': 'Transferencia',
      'categoria': 'ALQUILER',
      'descripcion': 'Alquiler del local',
      'fechaHora': '2026-10-09T23:45:00.000',
    };

    void sinGananciaNegativa(WidgetTester t) {
      final fila = find.ancestor(of: find.text('Alquiler del local'), matching: find.byType(Table));
      expect(find.descendant(of: fila, matching: find.text('—')), findsNWidgets(2));
      // Antes: "Costo $ 60.000,00" y "Ganancia −$ 60.000,00". Ahora el
      // único 60.000 de la fila es el monto.
      final pesos = NumberFormat.currency(locale: 'es_AR', symbol: r'$');
      expect(find.descendant(of: fila, matching: find.textContaining('60.000')), findsOneWidget);
      expect(find.text('- ${pesos.format(60000)}'), findsOneWidget);
    }

    testWidgets('en Movimientos se ve "—"', (t) async {
      pantallaGrande(t);
      final bloc = _MockFinanzasBloc();
      addTearDown(bloc.close);
      when(() => bloc.state).thenReturn(
          const MovimientosLoaded([alquiler], {}, pagina: 1, totalPaginas: 1));
      await t.pumpWidget(MaterialApp(
        home: BlocProvider<FinanzasBloc>.value(value: bloc, child: const MovimientosScreen()),
      ));
      await t.pumpAndSettle();
      sinGananciaNegativa(t);
    });

    testWidgets('en Ganancias se ve "—"', (t) async {
      pantallaGrande(t);
      final bloc = _MockFinanzasBloc();
      addTearDown(bloc.close);
      when(() => bloc.state).thenReturn(const BalanceLoaded({
        'totalIngresos': 0.0,
        'totalEgresos': 60000.0,
        'margenNeto': -60000.0,
        'costoTotal': 0.0,
        'gananciaReal': 0.0,
        'movimientos': [alquiler],
      }));
      await t.pumpWidget(MaterialApp(
        home: BlocProvider<FinanzasBloc>.value(value: bloc, child: const BalanceScreen()),
      ));
      await t.pumpAndSettle();
      sinGananciaNegativa(t);
    });
  });
}
