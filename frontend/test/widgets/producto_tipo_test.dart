import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/screens/catalogo_screen.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/producto_form_dialog.dart';

class _MockPosBloc extends MockBloc<PosEvent, PosState> implements PosBloc {}

class _FakePosApi implements PosApi {
  Map<String, dynamic>? createData;
  Map<String, dynamic>? updateData;

  @override
  Future<List<dynamic>> getProducts() async => [];

  @override
  Future<Product> createProduct(Map<String, dynamic> data) async {
    createData = data;
    return Product.fromJson(data);
  }

  @override
  Future<Product> updateProduct(String codigo, Map<String, dynamic> data) async {
    updateData = data;
    return Product.fromJson({...data, 'codigo': codigo});
  }

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {}

  @override
  Future<Product> ajustarStock(String codigo, {required int cantidad, required String motivo, String? tipo}) async =>
      throw UnimplementedError();
}

/// Etapa 1: Productos muestra el tipo; solo se crea reventa y un elaborado
/// puede marcarse como preparación base.
void main() {
  final tarta = Product(codigo: 'ELA-1', nombre: 'Tarta de coco', precioUnitario: 10800, stockActual: 4,
      tipo: 'ELABORADO', precioCosto: 4895, porcentajeGanancia: 120);
  final ganache = Product(codigo: 'ELA-2', nombre: 'Ganache', precioUnitario: 4700, stockActual: 0,
      tipo: 'ELABORADO', vendible: false);
  final coca = Product(codigo: 'REV-1', nombre: 'Coca-Cola', precioUnitario: 1500, stockActual: 24);

  Future<_FakePosApi> abrirFormulario(WidgetTester tester, {Product? producto}) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final api = _FakePosApi();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => PosBloc(apiService: api),
        child: Scaffold(body: Center(child: ProductoFormDialog(productoAEditar: producto))),
      ),
    ));
    await tester.pumpAndSettle();
    return api;
  }

  Future<void> guardar(WidgetTester tester) async {
    final boton = find.widgetWithText(ElevatedButton, 'Guardar Producto');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  testWidgets('alta: avisa que es reventa y envía tipo REVENTA', (tester) async {
    final api = await abrirFormulario(tester);

    expect(find.text('Tipo: Reventa. Los productos elaborados se crean desde Recetas.'), findsOneWidget);
    expect(find.byKey(const Key('preparacion_base_check')), findsNothing);
    // Corrección 9: el código no se escribe, lo genera el sistema.
    expect(find.text('El código se genera automáticamente al guardar.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Código (SKU)'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del Producto'), 'Agua');
    await tester.enterText(find.widgetWithText(TextFormField, 'Precio Unitario (\$)'), '900');
    await tester.pump();
    await guardar(tester);

    expect(api.createData!['tipo'], 'REVENTA');
    expect(api.createData!.containsKey('codigo'), isFalse);
  });

  testWidgets('editar un elaborado permite marcarlo como preparación base', (tester) async {
    final api = await abrirFormulario(tester, producto: tarta);

    expect(find.text('Tipo: Elaborado'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('preparacion_base_check')));
    await tester.tap(find.byKey(const Key('preparacion_base_check')));
    await tester.pump();
    await guardar(tester);

    expect(api.updateData!['vendible'], isFalse);
    expect(api.updateData!.containsKey('tipo'), isFalse);
  });

  testWidgets('editar un producto de reventa no ofrece preparación base', (tester) async {
    final api = await abrirFormulario(tester, producto: coca);

    expect(find.text('Tipo: Reventa'), findsOneWidget);
    expect(find.byKey(const Key('preparacion_base_check')), findsNothing);
    await guardar(tester);

    expect(api.updateData!.containsKey('vendible'), isFalse);
  });

  testWidgets('la tabla de Productos muestra el tipo de cada producto', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final bloc = _MockPosBloc();
    whenListen(bloc, const Stream<PosState>.empty(),
        initialState: PosState.initial().copyWith(products: [tarta, ganache, coca]));

    await tester.pumpWidget(MaterialApp(
        home: BlocProvider<PosBloc>.value(value: bloc, child: const CatalogoScreen())));
    await tester.pump();

    String tipo(String codigo) => (tester.widget<Container>(find.byKey(Key('tipo_$codigo'))).child as Text).data!;
    expect(tipo('ELA-1'), 'Elaborado');
    expect(tipo('ELA-2'), 'Preparación base');
    expect(tipo('REV-1'), 'Reventa');
  });
}
