import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/producto_form_dialog.dart';

class _FakePosApi implements PosApi {
  String? updateCodigo;
  Map<String, dynamic>? updateData;
  String? stockCodigo;
  int? stockCantidad;
  String? stockMotivo;
  bool getProductsCalled = false;

  @override
  Future<List<dynamic>> getProducts() async {
    getProductsCalled = true;
    return [
      {
        'codigo': 'P1',
        'nombre': 'Producto 1',
        'precioUnitario': 100,
        'stockActual': 10,
        'activo': true,
      },
    ];
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    return Product.fromJson(productData);
  }

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {}

  @override
  Future<Product> updateProduct(
      String codigo, Map<String, dynamic> productData) async {
    updateCodigo = codigo;
    updateData = productData;
    return Product.fromJson({
      'codigo': codigo,
      'nombre': productData['nombre'],
      'precioUnitario': productData['precioUnitario'],
      'stockActual': 10,
      'activo': productData['activo'] ?? true,
    });
  }

  @override
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo}) async {
    stockCodigo = codigo;
    stockCantidad = cantidad;
    stockMotivo = motivo;
    return Product.fromJson({
      'codigo': codigo,
      'nombre': 'Producto 1',
      'precioUnitario': 100,
      'stockActual': 15,
      'activo': true,
    });
  }
}

void main() {
  testWidgets('editar con ajuste manual envía el delta y cierra el diálogo',
      (WidgetTester tester) async {
    final fake = _FakePosApi();
    final product = Product(
        codigo: 'P1',
        nombre: 'Producto 1',
        precioUnitario: 100,
        stockActual: 10);

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

    // En modo edición se muestra el panel de ajuste de stock.
    expect(find.text('Editar Producto'), findsOneWidget);
    expect(find.text('Stock actual: 10 unidades'), findsOneWidget);

    // Ingresamos una cantidad y dejamos la opción por defecto (sumar).
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cantidad'), '5');
    await tester.pump();
    expect(find.text('Stock resultante: 15 unidades'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
    await tester.pumpAndSettle();

    // El diálogo se cerró con éxito.
    expect(find.text('Editar Producto'), findsNothing);

    // El update fue al endpoint /editar sin stockActual, y el ajuste al /stock.
    expect(fake.updateCodigo, 'P1');
    expect(fake.updateData!.containsKey('stockActual'), isFalse);
    expect(fake.stockCodigo, 'P1');
    expect(fake.stockCantidad, 5);
    expect(fake.stockMotivo, 'Ajuste manual desde edición');
    expect(fake.getProductsCalled, isTrue);
  });

  testWidgets('editar sin cantidad de ajuste no llama al endpoint /stock',
      (WidgetTester tester) async {
    final fake = _FakePosApi();
    final product = Product(
        codigo: 'P1',
        nombre: 'Producto 1',
        precioUnitario: 100,
        stockActual: 10);

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

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Producto'), findsNothing);
    expect(fake.updateCodigo, 'P1');
    expect(fake.stockCodigo, isNull);
    expect(fake.stockCantidad, isNull);
  });
}