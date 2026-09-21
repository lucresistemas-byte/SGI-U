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
      'MovimientosScreen renderiza tarjeta Costo vs Beneficio del día y columnas Costo y Ganancia en la tabla',
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

    // 1. Verificar tarjeta "Costo vs Beneficio del día"
    expect(find.text('Costo vs Beneficio del día'), findsOneWidget);

    // 2. Verificar valores formateados en la tarjeta
    final formattedCosto = currencyFormatter.format(2000.0);
    final formattedGanancia = currencyFormatter.format(4000.0);
    expect(find.text(formattedCosto), findsWidgets);
    expect(find.text('+ $formattedGanancia'), findsWidgets);

    // 3. Verificar columnas de la tabla de movimientos
    expect(find.text('Costo'), findsWidgets);
    expect(find.text('Ganancia'), findsWidgets);
    expect(find.text('Venta salón'), findsOneWidget);
  });
}
