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
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/screens/balance_screen.dart';
import 'package:sgi_u_frontend/screens/movimientos_screen.dart';
import 'package:sgi_u_frontend/utils/numeros.dart';
import 'package:sgi_u_frontend/utils/textos_finanzas.dart';

class _MockFinanzasBloc extends MockBloc<FinanzasEvent, FinanzasState>
    implements FinanzasBloc {}

/// Balance y Movimientos con sus textos originales, Costo y Ganancia neta en
/// tarjetas separadas, y los egresos sin costo ni ganancia ("—").
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_AR', null);
  });

  void pantallaGrande(WidgetTester t) {
    t.view.physicalSize = const Size(1920, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  test('el menú conserva Dashboard y Balance', () {
    expect(Seccion.dashboard.etiqueta, 'Dashboard');
    expect(Seccion.dashboard.icono, Icons.dashboard_outlined);
    expect(Seccion.balance.etiqueta, 'Balance');
  });

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

  /// Monto de la tarjeta con ese título (el Text con $ debajo del título).
  Finder tarjeta(String titulo) => find.ancestor(of: find.text(titulo), matching: find.byType(Container)).first;

  Future<void> abrirBalance(WidgetTester t, Map<String, dynamic> balance) async {
    pantallaGrande(t);
    final bloc = _MockFinanzasBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(BalanceLoaded(balance));
    await t.pumpWidget(MaterialApp(
      home: BlocProvider<FinanzasBloc>.value(value: bloc, child: const BalanceScreen()),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('Balance: textos originales; Costo y Ganancia neta en tarjetas separadas', (t) async {
    await abrirBalance(t, {
      'totalIngresos': 76800.0,
      'totalEgresos': 123000.0,
      'margenNeto': -46200.0,
      'costoTotal': 37905.0,
      'gananciaReal': -39105.0,
      'movimientos': [alquiler],
      'resultado': {'gastos': 78000.0, 'margenNetoPorcentaje': -50.92},
    });

    for (final texto in ['Balance', 'Rango de Fechas', 'Total de Ingresos', 'Total de Egresos', 'Saldo de caja del período', 'Costo', 'Ganancia neta']) {
      expect(find.text(texto), findsWidgets, reason: texto);
    }
    for (final viejo in ['Ganancias', 'Costo y ganancia', 'Te costó', 'Caja del período', 'Costo vs Beneficio', 'Ganancia Real', 'Margen Neto']) {
      expect(find.text(viejo), findsNothing, reason: viejo);
    }
    final pesos = NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);
    expect(find.descendant(of: tarjeta('Costo').first, matching: find.text(pesos.format(37905))), findsOneWidget);
    expect(find.descendant(of: tarjeta('Ganancia neta'), matching: find.text(formatPesosConSigno(-39105))), findsOneWidget);
    expect(find.descendant(of: tarjeta('Ganancia neta'), matching: find.byIcon(Icons.info_outline)), findsOneWidget);
    // Explicaciones: saldo y ganancia neta negativos traen su segunda línea.
    Finder en(String key, String texto) =>
        find.descendant(of: find.byKey(Key(key)), matching: find.text(texto));
    const cuando = TextosFinanzas.entreFechas;
    expect(en('balance_ingresos', TextosFinanzas.ingresos(cuando)), findsOneWidget);
    expect(en('balance_egresos', TextosFinanzas.egresos(cuando)), findsOneWidget);
    expect(en('balance_saldo_caja', TextosFinanzas.saldoCaja(cuando)), findsOneWidget);
    expect(en('balance_saldo_caja', TextosFinanzas.saldoCajaNegativo), findsOneWidget);
    expect(en('balance_costo', TextosFinanzas.costo), findsOneWidget);
    expect(en('balance_ganancia_neta', TextosFinanzas.gananciaNeta('\$ 78.000,00')), findsOneWidget);
    expect(en('balance_ganancia_neta', TextosFinanzas.gananciaNetaNegativa), findsOneWidget);
    expect(en('balance_ganancia_neta', '\u221250,9 %'), findsOneWidget);
    // Más grandes: saldo de caja y ganancia neta.
    expect(t.getSize(find.byKey(const Key('balance_saldo_caja'))).width,
        greaterThan(t.getSize(find.byKey(const Key('balance_ingresos'))).width));
    expect(t.getSize(find.byKey(const Key('balance_saldo_caja'))).height,
        greaterThan(t.getSize(find.byKey(const Key('balance_egresos'))).height - 1));
    expect(t.getSize(find.byKey(const Key('balance_ganancia_neta'))).width,
        greaterThan(t.getSize(find.byKey(const Key('balance_costo'))).width));
    // Categoría legible y sin la paginación fija.
    expect(find.text('Alquiler'), findsOneWidget);
    expect(find.text('Página 1 de 1'), findsNothing);
  });

  testWidgets('Movimientos: textos originales; Costo y Ganancia neta en tarjetas separadas', (t) async {
    pantallaGrande(t);
    final bloc = _MockFinanzasBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(const MovimientosLoaded([], {
      'ingresosHoy': 6000.0,
      'egresosHoy': 1000.0,
      'saldoActual': -46200.0,
      'costoTotalHoy': 2000.0,
      'gananciaRealHoy': 3000.0,
      'gastosHoy': 1000.0,
    }, pagina: 1, totalPaginas: 1));
    await t.pumpWidget(MaterialApp(
      home: BlocProvider<FinanzasBloc>.value(value: bloc, child: const MovimientosScreen()),
    ));
    await t.pumpAndSettle();

    for (final texto in ['Ingresos Totales (Hoy)', 'Egresos Totales (Hoy)', 'Saldo de caja (Hoy)', 'Saldo de caja del mes', 'Costo', 'Ganancia neta']) {
      expect(find.text(texto), findsOneWidget, reason: texto);
    }
    for (final viejo in ['Costo y ganancia de hoy', 'Te costó', 'Caja del mes (entró − salió)', 'Saldo Neto (Hoy)', 'Saldo Actual']) {
      expect(find.text(viejo), findsNothing, reason: viejo);
    }
    expect(find.descendant(of: tarjeta('Ganancia neta'), matching: find.text(formatPesosConSigno(3000))), findsOneWidget);

    // Explicaciones de hoy; con todo positivo no hay líneas de negativo,
    // salvo el saldo del mes (−46.200).
    expect(find.text(TextosFinanzas.ingresos(TextosFinanzas.hoy)), findsOneWidget);
    expect(find.text(TextosFinanzas.egresos(TextosFinanzas.hoy)), findsOneWidget);
    expect(find.text(TextosFinanzas.saldoCaja(TextosFinanzas.hoy)), findsOneWidget);
    expect(find.text(TextosFinanzas.saldoCaja(TextosFinanzas.enElMes)), findsOneWidget);
    expect(find.text(TextosFinanzas.saldoCajaNegativo), findsOneWidget);
    expect(find.text(TextosFinanzas.costo), findsOneWidget);
    expect(find.text(TextosFinanzas.gananciaNeta('\$ 1.000,00')), findsOneWidget);
    expect(find.text(TextosFinanzas.gananciaNetaNegativa), findsNothing);
  });

  group('egresos sin costo ni ganancia', () {
    void sinGanancia(WidgetTester t) {
      final fila = find.ancestor(of: find.text('Alquiler del local'), matching: find.byType(Table));
      expect(find.descendant(of: fila, matching: find.text('—')), findsNWidgets(2));
      // El único 60.000 de la fila es el monto.
      expect(find.descendant(of: fila, matching: find.textContaining('60.000')), findsOneWidget);
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
      sinGanancia(t);
    });

    testWidgets('en Balance se ve "—"', (t) async {
      await abrirBalance(t, const {
        'totalIngresos': 0.0,
        'totalEgresos': 60000.0,
        'margenNeto': -60000.0,
        'costoTotal': 0.0,
        'gananciaReal': 0.0,
        'movimientos': [alquiler],
      });
      sinGanancia(t);
    });
  });
}
