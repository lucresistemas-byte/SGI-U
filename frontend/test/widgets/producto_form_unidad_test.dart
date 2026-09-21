import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/producto_form_dialog.dart';

class _FakePosApi implements PosApi {
  Map<String, dynamic>? createdData;
  String? updatedCodigo;
  Map<String, dynamic>? updatedData;

  @override
  Future<List<dynamic>> getProducts() async => [];

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    createdData = productData;
    return Product.fromJson(productData);
  }

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {}

  @override
  Future<Product> updateProduct(
      String codigo, Map<String, dynamic> productData) async {
    updatedCodigo = codigo;
    updatedData = productData;
    return Product.fromJson(productData);
  }

  @override
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo}) async {
    return Product(
      codigo: codigo,
      nombre: 'Test',
      precioUnitario: 100,
      stockActual: 10,
    );
  }
}

void main() {
  testWidgets('Selector de unidad de medida renderiza opciones y envía unidad_medida KILO en payload al crear',
      (WidgetTester tester) async {
    final fake = _FakePosApi();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PosBloc(apiService: fake),
          child: const Scaffold(
            body: Center(
              child: ProductoFormDialog(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verificamos que el dropdown exista con el valor inicial UNIDAD
    final dropdownFinder = find.byKey(const ValueKey('producto_form_unidad_medida_dropdown'));
    expect(dropdownFinder, findsOneWidget);
    expect(find.text('UNIDAD'), findsOneWidget);

    // Abrimos el dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Verificamos que se listen las opciones configurables
    expect(find.byKey(const ValueKey('unidad_item_GRAMO')).last, findsOneWidget);
    expect(find.byKey(const ValueKey('unidad_item_KILO')).last, findsOneWidget);
    expect(find.byKey(const ValueKey('unidad_item_UNIDAD')).last, findsOneWidget);
    expect(find.byKey(const ValueKey('unidad_item_CAJA')).last, findsOneWidget);
    expect(find.byKey(const ValueKey('unidad_item_METRO')).last, findsOneWidget);
    expect(find.byKey(const ValueKey('unidad_item_LITRO')).last, findsOneWidget);

    // Seleccionamos "KILO"
    await tester.tap(find.text('KILO').last);
    await tester.pumpAndSettle();

    // Completamos los campos requeridos
    await tester.enterText(find.widgetWithText(TextFormField, 'Código (SKU)'), 'HAR-01');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del Producto'), 'Harina Pureza');
    await tester.enterText(find.widgetWithText(TextFormField, 'Precio Unitario (\$)'), '1500');
    await tester.enterText(find.widgetWithText(TextFormField, 'Stock Inicial'), '25');
    await tester.pumpAndSettle();

    // Guardamos el producto
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
    await tester.pumpAndSettle();

    // Verificamos que el payload enviado contenga unidad_medida = KILO
    expect(fake.createdData, isNotNull);
    expect(fake.createdData!['codigo'], 'HAR-01');
    expect(fake.createdData!['nombre'], 'Harina Pureza');
    expect(fake.createdData!['unidad_medida'], 'KILO');
    expect(fake.createdData!['unidadMedida'], 'KILO');
  });

  testWidgets('Selector de unidad en modo edición inicia con la unidad del producto y envía el cambio',
      (WidgetTester tester) async {
    final fake = _FakePosApi();
    final product = Product(
      codigo: 'MET-01',
      nombre: 'Manguera',
      precioUnitario: 500.0,
      stockActual: 100,
      unidadMedida: 'METRO',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PosBloc(apiService: fake),
          child: Scaffold(
            body: Center(
              child: ProductoFormDialog(productoAEditar: product),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Inicialmente debe mostrar METRO
    expect(find.text('METRO'), findsOneWidget);

    // Cambiamos a LITRO
    final dropdownFinder = find.byKey(const ValueKey('producto_form_unidad_medida_dropdown'));
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('LITRO').last);
    await tester.pumpAndSettle();

    // Guardar
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
    await tester.pumpAndSettle();

    expect(fake.updatedCodigo, 'MET-01');
    expect(fake.updatedData, isNotNull);
    expect(fake.updatedData!['unidad_medida'], 'LITRO');
    expect(fake.updatedData!['unidadMedida'], 'LITRO');
  });
}
