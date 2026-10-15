import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/models/stock.dart';
import 'package:sgi_u_frontend/screens/catalogo_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/produccion_dialog.dart';
import 'package:sgi_u_frontend/widgets/stock_historial_dialog.dart';

class _MockApi extends Mock implements ApiService {}

class _MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

/// Etapa 5 en el frontend: producir en dos pasos, historial de stock y stock
/// negativo en rojo.
void main() {
  final tarta = Product(
      codigo: 'ELA-0001', nombre: 'Tarta de coco', precioUnitario: 11800, stockActual: 4, tipo: 'ELABORADO',
      puedeProducir: 1);
  late _MockApi api;

  setUp(() => api = _MockApi());

  void pantalla(WidgetTester t) {
    t.view.physicalSize = const Size(1500, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  testWidgets('producir: si faltan componentes avisa sin aplicar y con "Producir igual" confirma', (t) async {
    pantalla(t);
    when(() => api.producir('ELA-0001', cantidad: 2, confirmarFaltantes: false, motivo: any(named: 'motivo')))
        .thenThrow(const ApiException('No alcanzan los componentes', codigo: 'FALTAN_COMPONENTES', datos: {
      'faltantes': [
        {'codigo': 'MP-0002', 'nombre': 'Coco rallado', 'mensaje': 'Faltan 120 g de Coco rallado: hay 380 g, se necesitan 500 g.'}
      ]
    }));
    when(() => api.producir('ELA-0001', cantidad: 2, confirmarFaltantes: true, motivo: any(named: 'motivo')))
        .thenAnswer((_) async => const ResultadoProduccion(
            codigo: 'ELA-0001', nombre: 'Tarta de coco', cantidad: 2, conFaltantes: true, stockActual: 6));
    ResultadoProduccion? resultado;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              resultado = await showDialog<ResultadoProduccion>(
                  context: context, builder: (_) => ProduccionDialog(producto: tarta, apiService: api));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    expect(find.text('Con el stock actual se pueden producir hasta 1.'), findsOneWidget);

    await t.enterText(find.byKey(const Key('produccion_cantidad_input')), '2');
    await t.tap(find.byKey(const Key('producir_button')));
    await t.pumpAndSettle();

    expect(find.text('No alcanza el stock. No se aplicó nada.'), findsOneWidget);
    expect(find.text('• Faltan 120 g de Coco rallado: hay 380 g, se necesitan 500 g.'), findsOneWidget);
    expect(resultado, isNull);

    await t.tap(find.byKey(const Key('producir_igual_button')));
    await t.pumpAndSettle();
    expect(resultado!.conFaltantes, isTrue);
    verify(() => api.producir('ELA-0001', cantidad: 2, confirmarFaltantes: true, motivo: any(named: 'motivo')))
        .called(1);
  });

  testWidgets('historial de stock: movimientos, negativo en rojo y filtro por tipo', (t) async {
    pantalla(t);
    when(() => api.getMovimientosStock(any(),
            desde: any(named: 'desde'), hasta: any(named: 'hasta'), tipo: any(named: 'tipo')))
        .thenAnswer((_) async => [
              MovimientoStock(
                  id: 2,
                  fecha: DateTime(2026, 10, 14, 11),
                  tipo: 'CONSUMO_PRODUCCION',
                  tipoDescripcion: 'Consumo de producción',
                  cantidad: -500,
                  cantidadTexto: '−500 g',
                  stockResultante: -120,
                  stockResultanteTexto: '−120 g',
                  motivo: 'Producción de 2 Tarta de coco (ELA-0001)',
                  usuario: 'admin'),
            ]);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: StockHistorialDialog(codigo: 'MP-0002', nombre: 'Coco rallado', apiService: api))));
    await t.pumpAndSettle();

    expect(find.text('Consumo de producción'), findsOneWidget);
    final resultante = t.widget<Text>(find.byKey(const Key('stock_resultante_2')));
    expect(resultante.data, '−120 g');
    expect(resultante.style!.color, Colors.red.shade700);

    await t.tap(find.byKey(const Key('stock_historial_tipo')));
    await t.pumpAndSettle();
    await t.tap(find.text('Merma').last);
    await t.pumpAndSettle();
    verify(() => api.getMovimientosStock('MP-0002',
        desde: any(named: 'desde'), hasta: any(named: 'hasta'), tipo: 'MERMA')).called(1);
  });

  testWidgets('Productos: stock negativo en rojo, "puedo producir hasta" y botón Producir', (t) async {
    pantalla(t);
    final bloc = _MockPosBloc();
    addTearDown(bloc.close);
    final torta = Product(
        codigo: 'ELA-0002', nombre: 'Torta', precioUnitario: 31500, stockActual: -2, tipo: 'ELABORADO', puedeProducir: 0);
    final gaseosa = Product(codigo: 'REV-0001', nombre: 'Gaseosa', precioUnitario: 1500, stockActual: 23);
    when(() => bloc.state).thenReturn(PosState.initial().copyWith(products: [torta, gaseosa]));
    await t.pumpWidget(MaterialApp(
      home: BlocProvider<PosBloc>.value(value: bloc, child: CatalogoScreen(apiService: api)),
    ));
    await t.pumpAndSettle();

    final stock = t.widget<Text>(find.byKey(const Key('stock_ELA-0002')));
    expect(stock.data, '−2 unidades');
    expect(stock.style!.color, Colors.red.shade700);
    expect(find.text('Puedo producir hasta 0'), findsOneWidget);
    expect(find.byKey(const Key('producir_ELA-0002')), findsOneWidget);
    // La reventa no se produce, pero tiene historial.
    expect(find.byKey(const Key('producir_REV-0001')), findsNothing);
    expect(find.byKey(const Key('historial_stock_REV-0001')), findsOneWidget);
  });
}
