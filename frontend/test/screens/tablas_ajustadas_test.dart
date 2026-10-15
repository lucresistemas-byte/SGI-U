import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_bloc.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_event.dart';
import 'package:sgi_u_frontend/blocs/finanzas/finanzas_state.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_bloc.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_event.dart';
import 'package:sgi_u_frontend/blocs/insumos/insumos_state.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_event.dart';
import 'package:sgi_u_frontend/blocs/pedidos/pedidos_state.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/historial_precio.dart';
import 'package:sgi_u_frontend/models/insumo.dart';
import 'package:sgi_u_frontend/models/paquete.dart';
import 'package:sgi_u_frontend/models/pedido.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/screens/balance_screen.dart';
import 'package:sgi_u_frontend/screens/catalogo_screen.dart';
import 'package:sgi_u_frontend/screens/historial_precios_view.dart';
import 'package:sgi_u_frontend/screens/insumos_screen.dart';
import 'package:sgi_u_frontend/screens/movimientos_screen.dart';
import 'package:sgi_u_frontend/screens/paquetes_screen.dart';
import 'package:sgi_u_frontend/screens/pedidos_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/tabla_ajustada.dart';

class _MockApi extends Mock implements ApiService {}

class _MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

class _MockInsumosBloc extends MockBloc<InsumosEvent, InsumosState> implements InsumosBloc {}

class _MockFinanzasBloc extends MockBloc<FinanzasEvent, FinanzasState> implements FinanzasBloc {}

class _MockPedidosBloc extends MockBloc<PedidosEvent, PedidosState> implements PedidosBloc {}

/// fix/tabla-productos: las tablas entran en el ancho de la pantalla (Acciones
/// siempre a la vista), precios en formato argentino y stock con unidades
/// legibles.
void main() {
  // La fuente de los tests dibuja cada letra como un cuadrado (el doble de
  // ancha que una real): con Roboto los anchos se parecen a los de la app.
  setUpAll(() async {
    final carpeta = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    Future<ByteData> fuente(String archivo) async => ByteData.sublistView(await File('$carpeta/$archivo').readAsBytes());
    await (FontLoader('Roboto')
          ..addFont(fuente('Roboto-Regular.ttf'))
          ..addFont(fuente('Roboto-Bold.ttf')))
        .load();
    await initializeDateFormatting('es_AR', null);
  });

  void pantalla(WidgetTester t, double ancho) {
    t.view.physicalSize = Size(ancho, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  /// El scroll horizontal de la tabla no tiene recorrido: entra entera.
  void sinScrollHorizontal(WidgetTester t) {
    final scrolls = find.descendant(of: find.byType(TablaAjustada), matching: find.byType(Scrollable));
    final horizontales = t.stateList<ScrollableState>(scrolls).where((s) => s.axisDirection == AxisDirection.right);
    expect(horizontales, isNotEmpty);
    for (final estado in horizontales) {
      expect(estado.position.maxScrollExtent, 0);
    }
  }

  void dentroDeLaPantalla(WidgetTester t, Finder f, double ancho) {
    for (final e in f.evaluate()) {
      final caja = t.getRect(find.byWidget(e.widget));
      expect(caja.right, lessThanOrEqualTo(ancho), reason: '${e.widget.key} queda cortado');
    }
  }

  final productos = [
    Product(
        codigo: 'ELA-0001',
        nombre: 'Tarta de coco con dulce de leche y merengue italiano, porción grande para compartir',
        precioUnitario: 11800,
        stockActual: 4,
        tipo: 'ELABORADO',
        categoria: 'Tortas y tartas',
        gananciaPesos: 6455,
        precioCosto: 5345,
        puedeProducir: 1),
    Product(
        codigo: 'REV-0001',
        nombre: 'Bombones a granel',
        precioUnitario: 1234.5,
        stockActual: 0,
        unidadMedida: 'GRAMO',
        categoria: 'Chocolates',
        modoPrecio: 'MANUAL'),
  ];

  Future<void> montarProductos(WidgetTester t) async {
    final bloc = _MockPosBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(PosState.initial().copyWith(products: productos));
    await t.pumpWidget(MaterialApp(
      home: BlocProvider<PosBloc>.value(value: bloc, child: CatalogoScreen(apiService: _MockApi())),
    ));
    await t.pumpAndSettle();
  }

  for (final ancho in [1280.0, 1024.0]) {
    testWidgets('Productos a ${ancho.toInt()} px: la tabla entra y las acciones se ven', (t) async {
      pantalla(t, ancho);
      await montarProductos(t);

      expect(t.takeException(), isNull);
      sinScrollHorizontal(t);
      dentroDeLaPantalla(t, find.byKey(const Key('editar_producto_ELA-0001')), ancho);
      dentroDeLaPantalla(t, find.byKey(const Key('producir_ELA-0001')), ancho);
      dentroDeLaPantalla(t, find.byKey(const Key('historial_stock_ELA-0001')), ancho);
      dentroDeLaPantalla(t, find.byIcon(Icons.delete_outline), ancho);
    });
  }

  testWidgets('Productos: precios en formato argentino y stock con unidades legibles', (t) async {
    pantalla(t, 1280);
    await montarProductos(t);

    expect(t.widget<Text>(find.byKey(const Key('precio_ELA-0001'))).data, '\$ 11.800,00');
    expect(t.widget<Text>(find.byKey(const Key('precio_REV-0001'))).data, '\$ 1.234,50\n(a mano)');
    expect(t.widget<Text>(find.byKey(const Key('ganancia_ELA-0001'))).data, startsWith('\$ 6.455,00'));
    expect(t.widget<Text>(find.byKey(const Key('stock_ELA-0001'))).data, '4 unidades');
    expect(t.widget<Text>(find.byKey(const Key('stock_REV-0001'))).data, '0 g');
  });

  testWidgets('Materia Prima a 1024 px: la tabla entra, acciones visibles y stock legible', (t) async {
    pantalla(t, 1024);
    final bloc = _MockInsumosBloc();
    whenListen(bloc, const Stream<InsumosState>.empty(),
        initialState: const InsumosLoaded(insumos: [
          Insumo(
              id: 1,
              codigo: 'MP-0001',
              nombre: 'Harina 0000 leudante marca de la casa, bolsa grande',
              costoUnitario: 1.2,
              unidadMedida: 'GRAMO',
              stockActual: 2500),
          Insumo(id: 2, codigo: 'MP-0002', nombre: 'Huevo', costoUnitario: 250, stockActual: 4),
        ]));
    await t.pumpWidget(MaterialApp(home: InsumosScreen(insumosBloc: bloc)));
    await t.pump();

    expect(t.takeException(), isNull);
    sinScrollHorizontal(t);
    dentroDeLaPantalla(t, find.byKey(const Key('editar_insumo_MP-0001')), 1024);
    dentroDeLaPantalla(t, find.byKey(const Key('historial_stock_MP-0002')), 1024);
    expect(find.text('4 unidades'), findsOneWidget);
  });

  testWidgets('Pedidos a 1024 px: la tabla entra y Abonar/Cancelar se ven', (t) async {
    pantalla(t, 1024);
    final pedido = Pedido(
        id: 3,
        clienteNombre: 'Ana Pérez',
        clienteTelefono: '11-5555-0001',
        descripcion: 'Torta de chocolate de dos pisos con relleno de frutilla y decoración de cumpleaños',
        montoTotal: 39000,
        senia: 13000,
        fechaEntrega: DateTime(2026, 10, 20, 15, 30));
    final bloc = _MockPedidosBloc();
    whenListen(bloc, const Stream<PedidosState>.empty(),
        initialState: PedidosState(pedidos: [pedido], filteredPedidos: [pedido]));
    await t.pumpWidget(MaterialApp(home: PedidosScreen(pedidosBloc: bloc)));
    await t.pump();

    expect(t.takeException(), isNull);
    sinScrollHorizontal(t);
    dentroDeLaPantalla(t, find.byKey(const Key('abonar_pedido_3')), 1024);
    dentroDeLaPantalla(t, find.byKey(const Key('cancelar_pedido_3')), 1024);
  });

  testWidgets('Historial de precios a 1024 px: la tabla entra', (t) async {
    pantalla(t, 1024);
    final api = _MockApi();
    when(() => api.getHistorialPrecios(
            desde: any(named: 'desde'), hasta: any(named: 'hasta'), codigo: any(named: 'codigo')))
        .thenAnswer((_) async => [
              HistorialPrecio(
                  id: 1,
                  fecha: DateTime(2026, 10, 14, 10, 30),
                  codigo: 'ELA-0002',
                  nombre: 'Torta de chocolate y frutillas',
                  tipo: 'ELABORADO',
                  costoAnterior: 14970,
                  costoNuevo: 17370,
                  precioAnterior: 31500,
                  precioNuevo: 36500,
                  causa: 'Cambio en Chocolate cobertura semiamargo (MP-0005): de \$ 18.000,00 a \$ 21.000,00 el kg',
                  usuario: 'admin'),
            ]);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: HistorialPreciosView(apiService: api))));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    sinScrollHorizontal(t);
    dentroDeLaPantalla(t, find.text('admin'), 1024);
  });

  final movimiento = {
    'id': 101,
    'tipo': 'INGRESO',
    'monto': 39000.0,
    'costo': 17370.0,
    'ganancia': 21630.0,
    'metodoPago': 'MERCADO_PAGO',
    'categoria': 'Venta',
    'descripcion': 'Venta POS: Torta de chocolate x1, Tarta de coco x2, Bombones a granel 250 g, Caja regalo x1',
    'fechaHora': '2026-10-14T12:00:00.000',
  };

  Future<void> montarFinanzas(WidgetTester t, Widget pantallaFinanzas, FinanzasState estado) async {
    final bloc = _MockFinanzasBloc();
    addTearDown(bloc.close);
    when(() => bloc.state).thenReturn(estado);
    await t.pumpWidget(MaterialApp(home: BlocProvider<FinanzasBloc>.value(value: bloc, child: pantallaFinanzas)));
    await t.pumpAndSettle();
  }

  testWidgets('Movimientos a 1024 px: la tabla entra', (t) async {
    pantalla(t, 1024);
    await montarFinanzas(t, const MovimientosScreen(),
        MovimientosLoaded([movimiento], const {'ingresosHoy': 39000.0}, pagina: 1, totalPaginas: 1));

    expect(t.takeException(), isNull);
    sinScrollHorizontal(t);
    dentroDeLaPantalla(t, find.text('Mercado Pago'), 1024);
  });

  testWidgets('Balance a 1024 px: la tabla entra', (t) async {
    pantalla(t, 1024);
    await montarFinanzas(t, const BalanceScreen(), BalanceLoaded({'movimientos': [movimiento]}));

    expect(t.takeException(), isNull);
    sinScrollHorizontal(t);
  });

  testWidgets('Paquetes a 1024 px: la tabla entra y las acciones se ven', (t) async {
    pantalla(t, 1024);
    final api = _MockApi();
    when(() => api.getPaquetes()).thenAnswer((_) async => [
          Paquete(
              id: 7,
              codigo: 'PAQ-0001',
              nombre: 'Caja regalo día de la madre',
              precioVenta: 18500,
              costoArmado: 9200,
              montoFijo: 1550,
              gananciaPesos: 7750,
              armado: [
                for (final (i, n) in ['Caja kraft grande', 'Cinta raso 1 m', 'Bombones surtidos x12', 'Tarjeta'].indexed)
                  FilaArmado(articuloId: i, articuloNombre: n, cantidad: 1),
              ]),
        ]);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: PaquetesScreen(apiService: api))));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    sinScrollHorizontal(t);
    dentroDeLaPantalla(t, find.byKey(const Key('estado_paquete_PAQ-0001')), 1024);
  });

  group('TablaAjustada', () {
    DataTable tabla(String nombre) => DataTable(columns: const [
          DataColumn(label: Text('Código')),
          DataColumn(columnWidth: columnaFlexible, label: Text('Nombre')),
          DataColumn(label: Text('Acciones')),
        ], rows: [
          DataRow(cells: [
            const DataCell(Text('A-1')),
            DataCell(Text(nombre)),
            DataCell(IconButton(key: const Key('accion'), icon: const Icon(Icons.edit), onPressed: () {})),
          ]),
        ]);

    testWidgets('con lugar ocupa todo el ancho y la columna flexible se queda con el resto', (t) async {
      pantalla(t, 900);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: TablaAjustada(tabla: tabla('Corto')))));
      expect(t.getSize(find.byType(DataTable)).width, 900);
      expect(t.getRect(find.byKey(const Key('accion'))).right, lessThanOrEqualTo(900));
    });

    testWidgets('un nombre largo pasa a varios renglones en vez de empujar las acciones', (t) async {
      pantalla(t, 500);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: TablaAjustada(tabla: tabla('palabra ' * 40)))));
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(DataTable)).width, 500);
      expect(t.getRect(find.byKey(const Key('accion'))).right, lessThanOrEqualTo(500));
    });

    testWidgets('si ni así entra, hay scroll horizontal en vez de cortar', (t) async {
      pantalla(t, 120);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: TablaAjustada(tabla: tabla('Nombre')))));
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(DataTable)).width, greaterThan(120));
    });
  });
}
