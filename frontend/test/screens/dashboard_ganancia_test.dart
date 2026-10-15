import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/navigation/ir_a_seccion.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

/// Dashboard con su diseño original más Costo, Ganancia y Ganancia neta, la
/// columna Ganancia en el top y el filtro por producto (demo, 1 al 15/10).
void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  Map<String, dynamic> respuesta({bool conProducto = false}) => <String, dynamic>{
        'kpis': <String, dynamic>{
          'ingresosPeriodo': conProducto ? 42400.0 : 76800.0,
          'egresosPeriodo': conProducto ? null : 123000.0,
          'saldoNeto': conProducto ? null : -46200.0,
          'margenNetoPorcentaje': conProducto ? null : -60.16,
          'cantidadVentas': conProducto ? 2 : 5,
          'ticketPromedio': conProducto ? 21200.0 : 15360.0,
          'resultado': <String, dynamic>{
            'ventas': conProducto ? 42400.0 : 76800.0,
            'costoVendido': conProducto ? 20190.0 : 37905.0,
            'gananciaBruta': conProducto ? 22210.0 : 38895.0,
            'margenBrutoPorcentaje': conProducto ? 52.38 : 50.64,
            'otrosIngresos': conProducto ? null : 0.0,
            'gastos': conProducto ? null : 78000.0,
            'comprasMercaderia': conProducto ? null : 45000.0,
            'gananciaNeta': conProducto ? null : -39105.0,
            'margenNetoPorcentaje': conProducto ? null : -50.92,
          },
        },
        'graficos': <String, dynamic>{
          'topProductosMasVendidos': [
            if (!conProducto)
              {'nombre': 'Coca-Cola 500 ml', 'cantidadVendida': 3, 'montoTotal': 4500.0, 'costo': 2700.0, 'ganancia': 1800.0},
            {'nombre': 'Torta de chocolate', 'cantidadVendida': 2, 'montoTotal': 42400.0, 'costo': 20190.0, 'ganancia': 22210.0},
          ],
        },
      };

  late _MockApi api;
  final productosPedidos = <int?>[];

  setUp(() {
    productosPedidos.clear();
    api = _MockApi();
    when(() => api.getMetodosPago()).thenAnswer((_) async => const []);
    when(() => api.getProducts()).thenAnswer((_) async => [
          {'id': 2, 'nombre': 'Torta de chocolate', 'vendible': true},
          {'id': 4, 'nombre': 'Ganache de chocolate', 'vendible': false},
          {'id': 5, 'nombre': 'Coca-Cola 500 ml', 'vendible': true},
        ]);
    when(() => api.getDashboardData(
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
          metodoPagoId: any(named: 'metodoPagoId'),
          productoId: any(named: 'productoId'),
        )).thenAnswer((inv) async {
      final producto = inv.namedArguments[#productoId] as int?;
      productosPedidos.add(producto);
      return respuesta(conProducto: producto != null);
    });
  });

  Future<List<Seccion>> abrir(WidgetTester t) async {
    t.view.physicalSize = const Size(1600, 1600);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    final pedidas = <Seccion>[];
    await t.pumpWidget(MaterialApp(
      home: IrASeccion(ir: pedidas.add, child: DashboardScreen(apiService: api, hoy: DateTime(2026, 10, 15))),
    ));
    await t.pumpAndSettle();
    return pedidas;
  }

  Finder en(String key, String texto) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.text(texto));

  testWidgets('conserva los textos y secciones originales', (t) async {
    await abrir(t);
    for (final texto in [
      'SGI-U - Tablero de Control',
      'Resumen Ejecutivo',
      '¿Me está quedando plata?',
      'Ingresos del Período',
      'Egresos del Período',
      'Saldo Neto de Caja',
      'Capital disponible',
      '¿Cómo se está moviendo mi negocio?',
      'Cantidad de Ventas',
      'Ticket Promedio',
      'Evolución del Dinero',
      'Alertas Operativas (El Día a Día)',
      'Stock Crítico - Reposición Urgente',
      'Top Productos Más Vendidos',
      'Cant. Vendida',
      'Monto Generado',
      'Ver inventario completo',
      'Ver reporte completo',
      'Todos los productos',
    ]) {
      expect(find.text(texto), findsWidgets, reason: texto);
    }
  });

  testWidgets('Costo, Ganancia (con %) y Ganancia neta (con ⓘ)', (t) async {
    await abrir(t);
    expect(en('dashboard_costo', '\$ 37.905,00'), findsOneWidget);
    expect(en('dashboard_ganancia', '+\$ 38.895,00'), findsOneWidget);
    expect(en('dashboard_ganancia', '50,6 %'), findsOneWidget);
    expect(en('dashboard_ganancia_neta', '−\$ 39.105,00'), findsOneWidget);
    expect(en('dashboard_ganancia_neta', '−50,9 %'), findsOneWidget);
    final pesos = t.widget<Text>(en('dashboard_ganancia_neta', '−\$ 39.105,00'));
    final pct = t.widget<Text>(en('dashboard_ganancia_neta', '−50,9 %'));
    expect(pesos.style!.fontSize! > pct.style!.fontSize!, isTrue);
    expect(pesos.style!.color, const Color(0xFFD32F2F));

    final info = find.descendant(of: find.byKey(const Key('dashboard_ganancia_neta')), matching: find.byIcon(Icons.info_outline));
    final ayuda = t.widget<Tooltip>(find.ancestor(of: info, matching: find.byType(Tooltip)));
    expect(ayuda.message, contains('compras de mercadería no se restan'));
  });

  testWidgets('el top muestra la columna Ganancia', (t) async {
    await abrir(t);
    expect(en('dashboard_top_productos', 'Ganancia'), findsOneWidget);
    expect(en('dashboard_top_productos', '+\$ 1.800,00'), findsOneWidget);
    expect(en('dashboard_top_productos', '+\$ 22.210,00'), findsOneWidget);
  });

  testWidgets('filtro por producto: lista vendibles y filtra KPIs y top', (t) async {
    await abrir(t);
    expect(productosPedidos, [null]);

    await t.tap(find.byKey(const Key('dashboard_filtro_producto')));
    await t.pumpAndSettle();
    expect(find.text('Ganache de chocolate'), findsNothing); // no vendible
    await t.tap(find.text('Torta de chocolate').last);
    await t.pumpAndSettle();

    expect(productosPedidos.last, 2);
    // Los egresos no son de un producto.
    expect(find.text('—'), findsWidgets);
    expect(en('dashboard_ganancia_neta', '—'), findsOneWidget);
    expect(en('dashboard_ganancia_neta', 'Los gastos no se calculan por producto'), findsOneWidget);
    expect(en('dashboard_ganancia', '+\$ 22.210,00'), findsOneWidget);
    expect(en('dashboard_top_productos', 'Coca-Cola 500 ml'), findsNothing);

    await t.tap(find.byKey(const Key('dashboard_filtro_producto')));
    await t.pumpAndSettle();
    await t.tap(find.text('Todos los productos').last);
    await t.pumpAndSettle();
    expect(productosPedidos.last, isNull);
  });

  testWidgets('los links llevan a Productos y a Balance', (t) async {
    final pedidas = await abrir(t);
    await t.ensureVisible(find.byKey(const Key('dashboard_ver_inventario')));
    await t.tap(find.byKey(const Key('dashboard_ver_inventario')));
    await t.ensureVisible(find.byKey(const Key('dashboard_ver_reporte')));
    await t.tap(find.byKey(const Key('dashboard_ver_reporte')));
    expect(pedidas, [Seccion.catalogo, Seccion.balance]);
  });
}
