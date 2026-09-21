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
  group('ProductoFormDialog - Cálculo de Costo y Margen en Vivo (Tarea 4.3)', () {
    testWidgets(
        'Ingresar Costo y % de Ganancia actualiza el Precio de Venta en tiempo real',
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

      final costoFinder = find.byKey(const ValueKey('producto_form_costo_field'));
      final porcentajeFinder = find.byKey(const ValueKey('producto_form_porcentaje_field'));
      final precioFinder = find.byKey(const ValueKey('producto_form_precio_field'));

      expect(costoFinder, findsOneWidget);
      expect(porcentajeFinder, findsOneWidget);
      expect(precioFinder, findsOneWidget);

      // 1. Ingresamos Costo $100 y Margen 50%
      await tester.enterText(costoFinder, '100');
      await tester.pump();
      await tester.enterText(porcentajeFinder, '50');
      await tester.pump();

      // El campo de precio debe haberse calculado automáticamente en 150
      final TextFormField precioField = tester.widget(precioFinder);
      expect(precioField.controller?.text, '150');

      // 2. Modificamos el Margen a 25% -> Precio debe ser 125
      await tester.enterText(porcentajeFinder, '25');
      await tester.pump();
      final TextFormField precioField2 = tester.widget(precioFinder);
      expect(precioField2.controller?.text, '125');

      // 3. Modificamos el Precio de Venta a 200 -> Margen debe recalcularse a 100%
      await tester.enterText(precioFinder, '200');
      await tester.pump();
      final TextFormField porcentajeField = tester.widget(porcentajeFinder);
      expect(porcentajeField.controller?.text, '100');

      // 4. Completamos los campos requeridos y guardamos
      await tester.enterText(find.widgetWithText(TextFormField, 'Código (SKU)'), 'CALC-01');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del Producto'), 'Café Especial');
      await tester.enterText(find.widgetWithText(TextFormField, 'Stock Inicial'), '10');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Producto'));
      await tester.pumpAndSettle();

      // Verificamos que el payload contenga costo, margen y precio de venta
      expect(fake.createdData, isNotNull);
      expect(fake.createdData!['codigo'], 'CALC-01');
      expect(fake.createdData!['precioUnitario'], 200.0);
      expect(fake.createdData!['precio_costo'], 100.0);
      expect(fake.createdData!['porcentaje_ganancia'], 100.0);
    });

    testWidgets(
        'Modo edición carga costo y porcentaje previos del producto',
        (WidgetTester tester) async {
      final fake = _FakePosApi();
      final product = Product(
        codigo: 'EDIT-01',
        nombre: 'Galletitas',
        precioUnitario: 150.0,
        stockActual: 20,
        precioCosto: 100.0,
        porcentajeGanancia: 50.0,
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

      final TextFormField costoField = tester.widget(find.byKey(const ValueKey('producto_form_costo_field')));
      final TextFormField porcentajeField = tester.widget(find.byKey(const ValueKey('producto_form_porcentaje_field')));
      final TextFormField precioField = tester.widget(find.byKey(const ValueKey('producto_form_precio_field')));

      expect(costoField.controller?.text, '100');
      expect(porcentajeField.controller?.text, '50');
      expect(precioField.controller?.text, '150');
    });
  });
}
