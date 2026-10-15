import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Inicio con los números de la demo (docs/ANALISIS_FINANZAS.md, mes del 1
/// al 15 de octubre).
void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  final demo = <String, dynamic>{
    'kpis': <String, dynamic>{
      'ingresosPeriodo': 76800.0,
      'egresosPeriodo': 123000.0,
      'saldoNeto': -46200.0,
      'cantidadVentas': 5,
      'ticketPromedio': 15360.0,
      'resultado': <String, dynamic>{
        'ventas': 76800.0,
        'costoVendido': 37905.0,
        'gananciaBruta': 38895.0,
        'margenBrutoPorcentaje': 50.64,
        'otrosIngresos': 0.0,
        'gastos': 78000.0,
        'comprasMercaderia': 45000.0,
        'gananciaNeta': -39105.0,
        'margenNetoPorcentaje': -50.92,
      },
    },
    'graficos': <String, dynamic>{
      'topProductosPorGanancia': [
        {'nombre': 'Torta de chocolate', 'cantidadVendida': 2, 'ventas': 42400.0, 'costo': 20190.0, 'ganancia': 22210.0},
        {'nombre': 'Tarta de coco', 'cantidadVendida': 1, 'ventas': 10800.0, 'costo': 4895.0, 'ganancia': 5905.0},
        {'nombre': 'Caja de bombones 100 g', 'cantidadVendida': 2, 'ventas': 12000.0, 'costo': 7000.0, 'ganancia': 5000.0},
        {'nombre': 'Alfajor de maicena', 'cantidadVendida': 1, 'ventas': 5300.0, 'costo': 2120.0, 'ganancia': 3180.0},
        {'nombre': 'Coca-Cola 500 ml', 'cantidadVendida': 3, 'ventas': 4500.0, 'costo': 2700.0, 'ganancia': 1800.0},
      ],
    },
  };

  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(() => api.getMetodosPago()).thenAnswer((_) async => const []);
    when(() => api.getDashboardData(
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
          metodoPagoId: any(named: 'metodoPagoId'),
          productoId: any(named: 'productoId'),
        )).thenAnswer((_) async => demo);
  });

  Future<void> abrir(WidgetTester t) async {
    t.view.physicalSize = const Size(1280, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: DashboardScreen(apiService: api)));
    await t.pumpAndSettle();
  }

  testWidgets('"Lo que más plata te deja": 5 productos por ganancia en pesos', (t) async {
    await abrir(t);

    expect(find.text('Lo que más plata te deja'), findsOneWidget);
    expect(find.text('Los más vendidos'), findsNothing);

    final tabla = find.byKey(const Key('inicio_top_ganancia'));
    final nombres = t
        .widgetList<Text>(find.descendant(of: tabla, matching: find.byType(Text)))
        .map((w) => w.data)
        .toList();
    final orden = ['Torta de chocolate', 'Tarta de coco', 'Caja de bombones 100 g', 'Alfajor de maicena', 'Coca-Cola 500 ml']
        .map(nombres.indexOf)
        .toList();
    expect(orden.every((i) => i >= 0), isTrue);
    expect([...orden]..sort(), orden);

    expect(find.descendant(of: tabla, matching: find.text('+\$ 22.210,00')), findsOneWidget);
    expect(find.descendant(of: tabla, matching: find.text('\$ 42.400,00')), findsOneWidget);
    expect(find.descendant(of: tabla, matching: find.text('+\$ 1.800,00')), findsOneWidget);
    for (final col in ['Vendidos', 'Ventas', 'Ganancia']) {
      expect(find.descendant(of: tabla, matching: find.text(col)), findsOneWidget);
    }
  });

  testWidgets('tarjetas: Vendiste, Te costó, Ganancia bruta y neta (pesos primero)', (t) async {
    await abrir(t);

    Finder en(String key, String texto) =>
        find.descendant(of: find.byKey(Key(key)), matching: find.text(texto));

    expect(en('inicio_vendiste', 'Vendiste'), findsOneWidget);
    expect(en('inicio_vendiste', '\$ 76.800,00'), findsOneWidget);
    expect(en('inicio_vendiste', '5 ventas · promedio \$ 15.360,00'), findsOneWidget);
    expect(en('inicio_te_costo', '\$ 37.905,00'), findsOneWidget);
    expect(en('inicio_ganancia_bruta', '+\$ 38.895,00'), findsOneWidget);
    expect(en('inicio_ganancia_bruta', '50,6 %'), findsOneWidget);
    expect(en('inicio_ganancia_neta', '\u2212\$ 39.105,00'), findsOneWidget);
    expect(en('inicio_ganancia_neta', '\u221250,9 %'), findsOneWidget);
    expect(en('inicio_ganancia_neta', 'Después de \$ 78.000,00 de gastos'), findsOneWidget);

    // Verde la bruta, roja la neta; el monto más grande que el %.
    final bruta = t.widget<Text>(en('inicio_ganancia_bruta', '+\$ 38.895,00'));
    final neta = t.widget<Text>(en('inicio_ganancia_neta', '\u2212\$ 39.105,00'));
    final pct = t.widget<Text>(en('inicio_ganancia_neta', '\u221250,9 %'));
    expect(bruta.style!.color, const Color(0xFF008A3D));
    expect(neta.style!.color, const Color(0xFFD32F2F));
    expect(neta.style!.fontSize! > pct.style!.fontSize!, isTrue);

    // Ya no están las tarjetas de caja (pasaron a Ganancias).
    expect(find.text('Ingresos del período'), findsNothing);
    expect(find.text('Caja del período'), findsNothing);
  });

  testWidgets('el ⓘ de Ganancia neta explica que las compras no se restan', (t) async {
    await abrir(t);
    final info = find.descendant(
        of: find.byKey(const Key('inicio_ganancia_neta')), matching: find.byIcon(Icons.info_outline));
    await t.tap(info);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Las compras de mercadería no se restan'), findsOneWidget);
    await t.pump(const Duration(seconds: 10));
  });
}
