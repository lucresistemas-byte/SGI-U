import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/navigation/ir_a_seccion.dart';
import 'package:sgi_u_frontend/navigation/seccion.dart';
import 'package:sgi_u_frontend/screens/dashboard_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/utils/textos_finanzas.dart';

class _MockApi extends Mock implements ApiService {}

/// Dashboard: diseño original más Costo, Ganancia y Ganancia neta, la columna
/// Ganancia en el top, el filtro por tipo de producto y la explicación de
/// cada tarjeta (demo, 1 al 15/10).
void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  /// Con [tipo] = ELABORADO, ventas, costo, ganancia, cantidad, ticket y top
  /// son de los elaborados; egresos, saldo y ganancia neta no cambian.
  Map<String, dynamic> respuesta(String? tipo) {
    final elab = tipo == 'ELABORADO';
    return <String, dynamic>{
      'kpis': <String, dynamic>{
        'ingresosPeriodo': elab ? 58500.0 : 76800.0,
        'egresosPeriodo': 123000.0,
        'saldoNeto': -46200.0,
        'margenNetoPorcentaje': -60.16,
        'cantidadVentas': elab ? 4 : 5,
        'ticketPromedio': elab ? 14625.0 : 15360.0,
        'resultado': <String, dynamic>{
          'ventas': elab ? 58500.0 : 76800.0,
          'costoVendido': elab ? 27205.0 : 37905.0,
          'gananciaBruta': elab ? 31295.0 : 38895.0,
          'margenBrutoPorcentaje': elab ? 53.5 : 50.64,
          'otrosIngresos': 0.0,
          'gastos': 78000.0,
          'comprasMercaderia': 45000.0,
          'gananciaNeta': -39105.0,
          'margenNetoPorcentaje': -50.92,
        },
      },
      'graficos': <String, dynamic>{
        'topProductosMasVendidos': [
          if (!elab)
            {'nombre': 'Coca-Cola 500 ml', 'cantidadVendida': 3, 'montoTotal': 4500.0, 'costo': 2700.0, 'ganancia': 1800.0},
          {'nombre': 'Torta de chocolate', 'cantidadVendida': 2, 'montoTotal': 42400.0, 'costo': 20190.0, 'ganancia': 22210.0},
        ],
      },
    };
  }

  late _MockApi api;
  final tiposPedidos = <String?>[];

  setUp(() {
    tiposPedidos.clear();
    api = _MockApi();
    when(() => api.getMetodosPago()).thenAnswer((_) async => const []);
    when(() => api.getDashboardData(
          fechaDesde: any(named: 'fechaDesde'),
          fechaHasta: any(named: 'fechaHasta'),
          metodoPagoId: any(named: 'metodoPagoId'),
          productoId: any(named: 'productoId'),
          tipoProducto: any(named: 'tipoProducto'),
        )).thenAnswer((inv) async {
      final tipo = inv.namedArguments[#tipoProducto] as String?;
      tiposPedidos.add(tipo);
      return respuesta(tipo);
    });
  });

  Future<List<Seccion>> abrir(WidgetTester t) async {
    t.view.physicalSize = const Size(1600, 1800);
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
      'Saldo de caja del período',
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
      'Todos los tipos',
    ]) {
      expect(find.text(texto), findsWidgets, reason: texto);
    }
    // Sacados de la tarjeta de saldo de caja.
    expect(find.text('Capital disponible'), findsNothing);
    expect(find.textContaining('Margen Neto'), findsNothing);
    expect(find.text('Saldo Neto de Caja'), findsNothing);
  });

  testWidgets('cada tarjeta explica su número; la línea de negativo solo si es negativo', (t) async {
    await abrir(t);
    const cuando = TextosFinanzas.entreFechas;
    expect(en('dashboard_ingresos', TextosFinanzas.ingresos(cuando)), findsOneWidget);
    expect(en('dashboard_egresos', TextosFinanzas.egresos(cuando)), findsOneWidget);
    expect(TextosFinanzas.egresos(cuando), contains('compras de mercadería'));
    // Saldo −46.200: explicación y línea de negativo.
    expect(en('dashboard_saldo_caja', TextosFinanzas.saldoCaja(cuando)), findsOneWidget);
    expect(en('dashboard_saldo_caja', TextosFinanzas.saldoCajaNegativo), findsOneWidget);
    expect(en('dashboard_costo', TextosFinanzas.costo), findsOneWidget);
    // Ganancia positiva: sin línea de negativo.
    expect(en('dashboard_ganancia', TextosFinanzas.ganancia), findsOneWidget);
    expect(find.text(TextosFinanzas.gananciaNegativa), findsNothing);
    // Ganancia neta −39.105: con los $ 78.000 de gastos y la línea de negativo.
    expect(en('dashboard_ganancia_neta', TextosFinanzas.gananciaNeta('\$ 78.000,00')), findsOneWidget);
    expect(en('dashboard_ganancia_neta', TextosFinanzas.gananciaNetaNegativa), findsOneWidget);
    expect(en('dashboard_cantidad_ventas', TextosFinanzas.cantidadVentas(cuando)), findsOneWidget);
    expect(en('dashboard_ticket', TextosFinanzas.ticketPromedio), findsOneWidget);
    // Sin filtro de tipo no aparece la aclaración.
    expect(find.text(TextosFinanzas.noSeFiltraPorTipo), findsNothing);
  });

  testWidgets('saldo de caja y ganancia neta son más grandes que las demás', (t) async {
    await abrir(t);
    final saldo = t.getSize(find.byKey(const Key('dashboard_saldo_caja')));
    final ingresos = t.getSize(find.byKey(const Key('dashboard_ingresos')));
    final neta = t.getSize(find.byKey(const Key('dashboard_ganancia_neta')));
    final costo = t.getSize(find.byKey(const Key('dashboard_costo')));
    expect(saldo.width, greaterThan(ingresos.width));
    expect(saldo.height, greaterThan(ingresos.height));
    expect(neta.width, greaterThan(costo.width));
    expect(neta.height, greaterThan(costo.height));
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
    expect(info, findsOneWidget);
  });

  testWidgets('el top muestra la columna Ganancia', (t) async {
    await abrir(t);
    expect(en('dashboard_top_productos', 'Ganancia'), findsOneWidget);
    expect(en('dashboard_top_productos', '+\$ 1.800,00'), findsOneWidget);
    expect(en('dashboard_top_productos', '+\$ 22.210,00'), findsOneWidget);
  });

  testWidgets('filtro por tipo: ventas del tipo; los gastos aclaran que no se filtran', (t) async {
    await abrir(t);
    expect(tiposPedidos, [null]);

    await t.tap(find.byKey(const Key('dashboard_filtro_tipo')));
    await t.pumpAndSettle();
    for (final opcion in ['Elaborado', 'Reventa', 'Reventa + materia prima', 'Paquete']) {
      expect(find.text(opcion), findsWidgets, reason: opcion);
    }
    await t.tap(find.text('Elaborado').last);
    await t.pumpAndSettle();

    expect(tiposPedidos.last, 'ELABORADO');
    expect(en('dashboard_ingresos', '\$ 58.500,00'), findsNothing); // formato distinto: se busca por contenido
    expect(find.descendant(of: find.byKey(const Key('dashboard_ingresos')), matching: find.textContaining('58.500')), findsOneWidget);
    expect(en('dashboard_ingresos', TextosFinanzas.ingresosDeTipo(TextosFinanzas.entreFechas)), findsOneWidget);
    expect(en('dashboard_costo', '\$ 27.205,00'), findsOneWidget);
    expect(en('dashboard_ganancia', '+\$ 31.295,00'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('dashboard_cantidad_ventas')), matching: find.text('4')), findsOneWidget);
    expect(en('dashboard_top_productos', 'Coca-Cola 500 ml'), findsNothing);
    // Egresos, saldo de caja y ganancia neta: mismos valores, con la aclaración.
    expect(find.descendant(of: find.byKey(const Key('dashboard_egresos')), matching: find.textContaining('123.000')), findsOneWidget);
    expect(en('dashboard_ganancia_neta', '−\$ 39.105,00'), findsOneWidget);
    for (final key in ['dashboard_egresos', 'dashboard_saldo_caja', 'dashboard_ganancia_neta']) {
      expect(en(key, TextosFinanzas.noSeFiltraPorTipo), findsOneWidget, reason: key);
    }
    expect(en('dashboard_ingresos', TextosFinanzas.noSeFiltraPorTipo), findsNothing);

    await t.tap(find.byKey(const Key('dashboard_filtro_tipo')));
    await t.pumpAndSettle();
    await t.tap(find.text('Todos los tipos').last);
    await t.pumpAndSettle();
    expect(tiposPedidos.last, isNull);
    expect(find.text(TextosFinanzas.noSeFiltraPorTipo), findsNothing);
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
