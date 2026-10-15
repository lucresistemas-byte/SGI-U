import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_event.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_state.dart';
import 'package:sgi_u_frontend/screens/balance_screen.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

class _MockFinanzasBloc extends MockBloc<FinanzasEvent, FinanzasState>
    implements FinanzasBloc {}

/// Selector de período de Inicio y Ganancias: por defecto este mes y cada
/// opción se aplica en el momento. Hoy es el jueves 15/10/2026.
void main() {
  final hoy = DateTime(2026, 10, 15, 17, 30);

  setUpAll(() async {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CargarBalance(DateTime(2026), DateTime(2026)));
    await initializeDateFormatting('es_AR', null);
  });

  void pantalla(WidgetTester t) {
    t.view.physicalSize = const Size(1600, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  ChoiceChip chip(WidgetTester t, String nombre) => t.widget<ChoiceChip>(find.byKey(Key('periodo_$nombre')));

  group('Inicio', () {
    late _MockApi api;
    final pedidos = <(DateTime, DateTime)>[];

    setUp(() {
      pedidos.clear();
      api = _MockApi();
      when(() => api.getMetodosPago()).thenAnswer((_) async => const []);
      when(() => api.getDashboardData(
            fechaDesde: any(named: 'fechaDesde'),
            fechaHasta: any(named: 'fechaHasta'),
            metodoPagoId: any(named: 'metodoPagoId'),
            productoId: any(named: 'productoId'),
          )).thenAnswer((inv) async {
        pedidos.add((inv.namedArguments[#fechaDesde] as DateTime, inv.namedArguments[#fechaHasta] as DateTime));
        return <String, dynamic>{};
      });
    });

    testWidgets('por defecto este mes; Hoy, Esta semana y Mes pasado se aplican solos', (t) async {
      pantalla(t);
      await t.pumpWidget(MaterialApp(home: DashboardScreen(apiService: api, hoy: hoy)));
      await t.pumpAndSettle();

      expect(chip(t, 'mes').selected, isTrue);
      expect(pedidos.last, (DateTime(2026, 10, 1), DateTime(2026, 10, 15)));
      expect(find.text('01/10/2026 al 15/10/2026'), findsOneWidget);

      await t.tap(find.byKey(const Key('periodo_semana')));
      await t.pumpAndSettle();
      expect(pedidos.last, (DateTime(2026, 10, 12), DateTime(2026, 10, 15)));
      expect(chip(t, 'semana').selected, isTrue);

      await t.tap(find.byKey(const Key('periodo_hoy')));
      await t.pumpAndSettle();
      expect(pedidos.last, (DateTime(2026, 10, 15), DateTime(2026, 10, 15)));
      expect(find.text('15/10/2026'), findsOneWidget);

      await t.tap(find.byKey(const Key('periodo_mesPasado')));
      await t.pumpAndSettle();
      expect(pedidos.last, (DateTime(2026, 9, 1), DateTime(2026, 9, 30)));
      expect(pedidos, hasLength(4));
    });

    testWidgets('Elegir fechas: cancelar deja el período anterior', (t) async {
      pantalla(t);
      await t.pumpWidget(MaterialApp(home: DashboardScreen(apiService: api, hoy: hoy)));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('periodo_elegido')));
      await t.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      await t.tap(find.byIcon(Icons.close));
      await t.pumpAndSettle();

      expect(pedidos, hasLength(1));
      expect(chip(t, 'mes').selected, isTrue);
    });
  });

  testWidgets('Ganancias: sin botón Filtrar; cada opción recarga el balance', (t) async {
    pantalla(t);
    final bloc = _MockFinanzasBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(FinanzasInitial());

    await t.pumpWidget(MaterialApp(
      home: BlocProvider<FinanzasBloc>.value(value: bloc, child: BalanceScreen(hoy: hoy)),
    ));
    await t.pumpAndSettle();

    expect(find.text('Filtrar'), findsNothing);
    expect(chip(t, 'mes').selected, isTrue);
    verify(() => bloc.add(CargarBalance(DateTime(2026, 10, 1), DateTime(2026, 10, 15)))).called(1);

    await t.tap(find.byKey(const Key('periodo_semana')));
    await t.pumpAndSettle();
    verify(() => bloc.add(CargarBalance(DateTime(2026, 10, 12), DateTime(2026, 10, 15)))).called(1);

    await t.tap(find.byKey(const Key('periodo_mesPasado')));
    await t.pumpAndSettle();
    verify(() => bloc.add(CargarBalance(DateTime(2026, 9, 1), DateTime(2026, 9, 30)))).called(1);
  });
}
