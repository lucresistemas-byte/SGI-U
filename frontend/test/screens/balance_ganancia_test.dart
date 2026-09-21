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
import 'package:sgi_u_frontend/screens/balance_screen.dart';

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
        child: const BalanceScreen(),
      ),
    );
  }

  testWidgets(
      'BalanceScreen renderiza tarjeta Costo vs Beneficio con formato moneda y columnas de costo y ganancia en DataTable',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final balanceData = {
      'totalIngresos': 5000.0,
      'totalEgresos': 1000.0,
      'margenNeto': 4000.0,
      'costoTotal': 1500.0,
      'gananciaReal': 3500.0,
      'movimientos': [
        {
          'id': 1,
          'tipo': 'INGRESO',
          'monto': 5000.0,
          'costo': 1500.0,
          'ganancia': 3500.0,
          'metodoPago': 'EFECTIVO',
          'categoria': 'Ventas',
          'descripcion': 'Venta del día',
          'fechaHora': '2026-09-21T14:30:00.000',
        },
      ],
    };

    when(() => mockFinanzasBloc.state)
        .thenReturn(BalanceLoaded(balanceData));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // 1. Verificar tarjeta "Costo vs Beneficio"
    expect(find.text('Costo vs Beneficio'), findsOneWidget);
    expect(find.text('Ganancia Real'), findsOneWidget);

    // 2. Verificar formato de moneda en los valores de la tarjeta
    final formattedCosto = currencyFormatter.format(1500.0);
    final formattedGanancia = currencyFormatter.format(3500.0);

    // Debe encontrarse el costo y la ganancia formateados
    expect(find.text(formattedCosto), findsWidgets);
    expect(find.text(formattedGanancia), findsWidgets);

    // 3. Verificar columnas de DataTable
    expect(find.text('Fecha/Hora'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Monto'), findsOneWidget);
    expect(find.text('Costo'), findsWidgets); // En tarjeta y en encabezado de columna
    expect(find.text('Ganancia'), findsOneWidget); // Encabezado de columna
    expect(find.text('Método de Pago'), findsOneWidget);

    // 4. Verificar datos en las celdas
    expect(find.text('+ $formattedGanancia'), findsOneWidget);
    expect(find.text('Venta del día'), findsOneWidget);
  });
}
