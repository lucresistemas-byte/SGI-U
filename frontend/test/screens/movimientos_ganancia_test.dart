import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_event.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_state.dart';
import 'package:sgi_u_frontend/screens/movimientos_screen.dart';
import 'package:sgi_u_frontend/utils/numeros.dart';

class MockFinanzasBloc extends MockBloc<FinanzasEvent, FinanzasState>
    implements FinanzasBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFinanzasBloc mockFinanzasBloc;
  final currencyFormatter =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);

  setUpAll(() async {
    await initializeDateFormatting('es_AR', null);
  });

  setUp(() {
    mockFinanzasBloc = MockFinanzasBloc();
  });

  tearDown(() {
    mockFinanzasBloc.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<FinanzasBloc>.value(
        value: mockFinanzasBloc,
        child: const MovimientosScreen(),
      ),
    );
  }

  testWidgets(
      'MovimientosScreen renderiza las tarjetas Costo y Ganancia neta y columnas Costo y Ganancia en la tabla',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final resumen = {
      'ingresosHoy': 6000.0,
      'egresosHoy': 1000.0,
      'saldoActual': 5000.0,
      'costoTotalHoy': 2000.0,
      'gananciaRealHoy': 4000.0,
    };

    final movimientos = [
      {
        'id': 101,
        'tipo': 'INGRESO',
        'monto': 6000.0,
        'costo': 2000.0,
        'ganancia': 4000.0,
        'metodoPago': 'MERCADO_PAGO',
        'categoria': 'Comestibles',
        'descripcion': 'Venta salón',
        'fechaHora': '2026-09-21T12:00:00.000',
      },
    ];

    when(() => mockFinanzasBloc.state).thenReturn(
      MovimientosLoaded(movimientos, resumen, pagina: 1, totalPaginas: 1),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // 1. Verificar tarjetas "Costo" y "Ganancia neta" (separadas)
    expect(find.text('Ganancia neta'), findsOneWidget);

    // 2. Verificar valores formateados en la tarjeta
    final formattedCosto = currencyFormatter.format(2000.0);
    expect(find.text(formattedCosto), findsWidgets);
    expect(find.text(formatPesosConSigno(4000)), findsOneWidget);

    // 3. Verificar columnas de la tabla de movimientos
    expect(find.text('Costo'), findsWidgets);
    expect(find.text('Ganancia'), findsWidgets);
    expect(find.text('Venta salón'), findsOneWidget);
  });

  testWidgets(
      'F-2: sin ventas hoy, Costo y Ganancia neta muestran 0 aunque haya historia',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Hoy no hubo movimientos: el balance del día viene en cero.
    final resumen = {
      'ingresosHoy': 0.0,
      'egresosHoy': 0.0,
      'saldoActual': -46200.0,
      'costoTotalHoy': 0.0,
      'gananciaRealHoy': 0.0,
    };
    // Movimientos de días anteriores (antes se sumaban como "del día").
    final movimientos = [
      {
        'id': 1,
        'tipo': 'INGRESO',
        'monto': 13800.0,
        'costo': 6695.0,
        'ganancia': 7105.0,
        'metodoPago': 'Efectivo',
        'categoria': 'VENTA',
        'descripcion': 'Venta de productos - ID: 1',
        'fechaHora': '2026-10-11T23:45:00.000',
      },
      {
        'id': 7,
        'tipo': 'EGRESO',
        'monto': 60000.0,
        'costo': 60000.0,
        'ganancia': -60000.0,
        'metodoPago': 'Transferencia',
        'categoria': 'ALQUILER',
        'descripcion': 'Alquiler del local',
        'fechaHora': '2026-10-09T23:45:00.000',
      },
    ];

    when(() => mockFinanzasBloc.state).thenReturn(
      MovimientosLoaded(movimientos, resumen, pagina: 1, totalPaginas: 1),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    Finder tarjeta(String titulo) => find.ancestor(
          of: find.text(titulo),
          matching: find.byType(Container),
        ).first;
    // "Costo" también es una columna de la tabla: la tarjeta es la primera.
    final costo = tarjeta('Costo');
    final ganancia = tarjeta('Ganancia neta');
    expect(find.descendant(of: costo, matching: find.text(currencyFormatter.format(0))), findsOneWidget);
    expect(find.descendant(of: ganancia, matching: find.text(formatPesosConSigno(0))), findsOneWidget);
    // Nada de la historia: ni 66.695 de costo ni −52.895 de ganancia.
    expect(find.textContaining('66.695'), findsNothing);
    expect(find.textContaining('52.895'), findsNothing);
  });
}
