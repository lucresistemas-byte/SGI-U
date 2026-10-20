import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/theme/app_theme.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  const sizeDesktop = Size(1366, 768);
  const sizeMobile = Size(800, 600);

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 10, 20));
  });

  const sampleMetodos = [
    MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1),
    MetodoPago(id: 2, nombre: 'Transferencia', orden: 2),
    MetodoPago(id: 3, nombre: 'Mercado Pago', orden: 3),
  ];

  final sampleDashboardData = <String, dynamic>{
    'kpis': <String, dynamic>{
      'ingresosPeriodo': 125400.0,
      'egresosPeriodo': 48200.0,
      'saldoNeto': 77200.0,
      'margenNetoPorcentaje': 61.56,
      'cantidadVentas': 28,
      'ticketPromedio': 4478.57,
      'resultado': <String, dynamic>{
        'ventas': 125400.0,
        'costoVendido': 42100.0,
        'gananciaBruta': 83300.0,
        'margenBrutoPorcentaje': 66.42,
        'otrosIngresos': 0.0,
        'gastos': 25000.0,
        'comprasMercaderia': 23200.0,
        'gananciaNeta': 58300.0,
        'margenNetoPorcentaje': 46.49,
      },
    },
    'graficos': <String, dynamic>{
      'topProductosMasVendidos': [
        {
          'nombre': 'Torta Selva Negra',
          'cantidadVendida': 14,
          'montoTotal': 63000.0,
          'costo': 21000.0,
          'ganancia': 42000.0,
        },
        {
          'nombre': 'Medialunas de Manteca',
          'cantidadVendida': 45,
          'montoTotal': 36000.0,
          'costo': 12000.0,
          'ganancia': 24000.0,
        },
        {
          'nombre': 'Café Espresso Doble',
          'cantidadVendida': 22,
          'montoTotal': 26400.0,
          'costo': 9100.0,
          'ganancia': 17300.0,
        },
      ],
      'stockCritico': [
        {
          'nombre': 'Harina 0000 1kg',
          'stockActual': 2,
          'stockMinimo': 10,
          'estado': 'CRITICO',
        },
        {
          'nombre': 'Levadura Fresca',
          'stockActual': 0,
          'stockMinimo': 5,
          'estado': 'AGOTADO',
        },
      ],
    },
  };

  late _MockApiService mockApi;

  setUp(() {
    mockApi = _MockApiService();
    when(() => mockApi.getMetodosPago()).thenAnswer((_) async => sampleMetodos);
    when(() => mockApi.getDashboardData(
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
          metodoPagoId: any(named: 'metodoPagoId'),
          productoId: any(named: 'productoId'),
        )).thenAnswer((_) async => sampleDashboardData);
  });

  Widget buildDashboardApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: DashboardScreen(
        apiService: mockApi,
        hoy: DateTime(2026, 10, 20),
      ),
    );
  }

  group('Golden Tests - DashboardScreen', () {
    testWidgets('DashboardScreen - Desktop (1366x768)', (tester) async {
      tester.view.physicalSize = sizeDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('snapshots/dashboard_screen_desktop.png'),
      );
    });

    testWidgets('DashboardScreen - Tablet/Mobile (800x600)', (tester) async {
      tester.view.physicalSize = sizeMobile;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('snapshots/dashboard_screen_mobile.png'),
      );
    });
  });
}
