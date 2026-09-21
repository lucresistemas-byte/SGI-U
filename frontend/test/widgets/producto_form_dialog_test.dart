import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';
import 'package:sgi_u_frontend/widgets/producto_form_dialog.dart';

class _FakePosApi implements PosApi {
  Exception? createError;
  Map<String, dynamic>? createData;
  bool createCalled = false;
  bool getProductsCalled = false;

  @override
  Future<List<dynamic>> getProducts() async {
    getProductsCalled = true;
    return [
      {
        'codigo': 'P9',
        'nombre': 'Agua',
        'precioUnitario': 50,
        'stockActual': 0,
        'activo': true,
      },
    ];
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    createCalled = true;
    createData = productData;
    if (createError != null) throw createError!;
    return Product.fromJson(productData);
  }

  @override
  Future<void> createSale(Map<String, dynamic> saleData) async {}

  @override
  Future<Product> updateProduct(
      String codigo, Map<String, dynamic> productData) async {
    throw UnimplementedError();
  }

  @override
  Future<Product> ajustarStock(String codigo,
      {required int cantidad, required String motivo}) async {
    throw UnimplementedError();
  }
}

ElevatedButton _btnGuardar(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Guardar Producto'));

Future<void> _pumpDialog(WidgetTester tester, _FakePosApi fake,
    {Product? producto}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => PosBloc(apiService: fake),
        child: Scaffold(
          body: Center(
            child: ProductoFormDialog(productoAEditar: producto),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ProductoFormDialog - modo creación (N3)', () {
    late _FakePosApi fake;

    setUp(() {
      fake = _FakePosApi();
    });

    testWidgets('campos vacíos: el botón Guardar está deshabilitado',
        (WidgetTester tester) async {
      await _pumpDialog(tester, fake);

      expect(find.text('Nuevo Producto'), findsOneWidget);
      expect(_btnGuardar(tester).onPressed, isNull);
    });

    testWidgets('precio <= 0 o campos sin completar mantienen el botón '
        'deshabilitado', (WidgetTester tester) async {
      await _pumpDialog(tester, fake);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código (SKU)'), 'P9');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre del Producto'), 'Agua');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Precio Unitario (\$)'), '0');
      await tester.pump();

      expect(_btnGuardar(tester).onPressed, isNull);
    });

    testWidgets('formulario válido: habilita Guardar y crea el producto',
        (WidgetTester tester) async {
      await _pumpDialog(tester, fake);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código (SKU)'), 'P9');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre del Producto'), 'Agua');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Precio Unitario (\$)'), '50');
      await tester.pump();

      expect(_btnGuardar(tester).onPressed, isNotNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Producto'), findsNothing);
      expect(fake.createCalled, isTrue);
      expect(fake.createData!['codigo'], 'P9');
      expect(fake.createData!['nombre'], 'Agua');
      expect(fake.createData!['precioUnitario'], 50.0);
      expect(fake.getProductsCalled, isTrue);
    });

    testWidgets('el backend 409 muestra el mensaje de código duplicado',
        (WidgetTester tester) async {
      fake.createError = Exception('El código de producto ya existe');
      await _pumpDialog(tester, fake);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código (SKU)'), 'P1');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre del Producto'), 'Duplicado');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Precio Unitario (\$)'), '10');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('El código de producto ya existe'),
          findsOneWidget);
      expect(find.text('Nuevo Producto'), findsOneWidget);
    });
  });

  group('ProductoFormDialog - modo edición (N3)', () {
    late _FakePosApi fake;

    setUp(() {
      fake = _FakePosApi();
    });

    testWidgets('precarga los campos con los datos del producto',
        (WidgetTester tester) async {
      final producto = Product(
          codigo: 'P1',
          nombre: 'Café',
          precioUnitario: 150,
          stockActual: 10);

      await _pumpDialog(tester, fake, producto: producto);

      expect(find.text('Editar Producto'), findsOneWidget);
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('150.0'), findsOneWidget);
      expect(find.text('Stock actual: 10 unidades'), findsOneWidget);
    });
  });
}