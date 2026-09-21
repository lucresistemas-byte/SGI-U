import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

/// Implementación falsa de [PosApi] que registra las llamadas para poder
/// verificar el flujo de actualización + ajuste de stock.
class _FakePosApi implements PosApi {
  String? updateCodigo;
  Map<String, dynamic>? updateData;

  String? stockCodigo;
  int? stockCantidad;
  String? stockMotivo;

  int getProductsCount = 0;
  bool failStockAdjust = false;

  @override
  Future<List<dynamic>> getProducts() async {
    getProductsCount++;
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
    if (failStockAdjust) {
      throw Exception('El stock no puede quedar negativo.');
    }
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

Future<PosState> _esperarResultado(PosBloc bloc) {
  return bloc.stream.firstWhere(
    (s) => s.successMessage != null || s.errorMessage != null,
  );
}

void main() {
  test(
      'UpdateProduct con stockAjuste llama a updateProduct SIN stockActual y ajusta stock via /stock',
      () async {
    final fake = _FakePosApi();
    final bloc = PosBloc(apiService: fake);

    final futureState = _esperarResultado(bloc);
    // La recarga de productos se agenda tras el éxito: esperamos el estado
    // con productos poblados como prueba de que LoadProducts se ejecutó.
    final futureReload = bloc.stream.firstWhere((s) => s.products.isNotEmpty);
    bloc.add(const UpdateProduct('P1', {
      'codigo': 'P1',
      'nombre': 'Nuevo nombre',
      'precioUnitario': 120,
      'activo': true,
    }, stockAjuste: 5, stockMotivo: 'Ajuste manual desde edición'));
    final result = await futureState;

    expect(fake.updateCodigo, 'P1');
    expect(fake.updateData, {
      'codigo': 'P1',
      'nombre': 'Nuevo nombre',
      'precioUnitario': 120,
      'activo': true,
    });
    expect(fake.updateData!.containsKey('stockActual'), isFalse,
        reason: 'En edición no debe enviarse stockActual al endpoint /editar');
    expect(fake.stockCodigo, 'P1');
    expect(fake.stockCantidad, 5);
    expect(fake.stockMotivo, 'Ajuste manual desde edición');
    expect(result.successMessage, 'Producto actualizado con éxito');
    expect(result.errorMessage, isNull);

    final reloaded = await futureReload;
    expect(reloaded.products, hasLength(1),
        reason: 'Tras el éxito se recarga la lista de productos');

    await bloc.close();
  });

  test('UpdateProduct sin stockAjuste no toca el endpoint /stock', () async {
    final fake = _FakePosApi();
    final bloc = PosBloc(apiService: fake);

    final futureState = _esperarResultado(bloc);
    bloc.add(const UpdateProduct('P1', {
      'codigo': 'P1',
      'nombre': 'Sin ajuste',
      'precioUnitario': 90,
      'activo': true,
    }));
    final result = await futureState;

    expect(fake.updateData!['nombre'], 'Sin ajuste');
    expect(fake.stockCodigo, isNull);
    expect(fake.stockCantidad, isNull);
    expect(result.successMessage, 'Producto actualizado con éxito');

    await bloc.close();
  });

  test('Actualiza el dato pero reporta errorMessage si el ajuste de stock falla',
      () async {
    final fake = _FakePosApi()..failStockAdjust = true;
    final bloc = PosBloc(apiService: fake);

    final futureState = _esperarResultado(bloc);
    bloc.add(const UpdateProduct('P1', {
      'codigo': 'P1',
      'nombre': 'IFA',
      'precioUnitario': 80,
      'activo': true,
    }, stockAjuste: -50, stockMotivo: 'Ajuste manual desde edición'));
    final result = await futureState;

    expect(result.successMessage, isNull);
    expect(result.errorMessage, contains('El stock no puede quedar negativo.'));
    // El update igual se intentó (el dato se actualizó antes del error).
    expect(fake.updateData!['nombre'], 'IFA');

    await bloc.close();
  });
}