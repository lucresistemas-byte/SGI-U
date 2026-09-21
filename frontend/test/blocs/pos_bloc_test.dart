import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class MockPosApi extends Mock implements PosApi {}

Map<String, dynamic> _jsonP1() => {
      'codigo': 'P1',
      'nombre': 'Café',
      'precioUnitario': 150.0,
      'stockActual': 10,
      'activo': true,
    };

/// Carga el catálogo en el bloc y devuelve el estado resultante.
Future<PosState> _cargarCatalogo(PosBloc bloc) {
  final done = bloc.stream.firstWhere((s) => s.products.isNotEmpty);
  bloc.add(const LoadProducts());
  return done;
}

Future<PosState> _add1(PosBloc bloc, String codigo, int cantidad) {
  final done = bloc.stream.firstWhere((s) => s.cart[codigo]?.cantidad == cantidad);
  bloc.add(AddToCart(codigo, cantidad));
  return done;
}

void main() {
  group('PosBloc - carrito (N1)', () {
    test('AddToCart agrega un producto nuevo con su precio congelado',
        () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      final state = await _add1(bloc, 'P1', 3);

      expect(state.cart['P1']!.codigo, 'P1');
      expect(state.cart['P1']!.nombre, 'Café');
      expect(state.cart['P1']!.precioUnitario, 150.0);
      expect(state.cart['P1']!.cantidad, 3);
      await bloc.close();
    });

    test('AddToCart suma cantidad si el producto ya está en el carrito',
        () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 1);

      // AddToCart SUMA sobre la cantidad existente: 1 + 2 = 3 (salto directo).
      final sumado = bloc.stream.firstWhere((s) => s.cart['P1']!.cantidad == 3);
      bloc.add(const AddToCart('P1', 2));
      final state = await sumado;

      expect(state.cart['P1']!.cantidad, 3);
      expect(state.cart['P1']!.precioUnitario, 150.0);
      await bloc.close();
    });

    test('AddToCart con cantidad <= 0 no produce ningún cambio', () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);
      await _cargarCatalogo(bloc);

      var emisiones = 0;
      final sub = bloc.stream.listen((_) => emisiones++);
      bloc.add(const AddToCart('P1', 0));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(emisiones, 0);
      expect(bloc.state.cart, isEmpty);
      await sub.cancel();
      await bloc.close();
    });

    test('UpdateCartItemQuantity modifica la cantidad', () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 5);

      final updated =
          bloc.stream.firstWhere((s) => s.cart['P1']!.cantidad == 2);
      bloc.add(const UpdateCartItemQuantity('P1', 2));
      final state = await updated;

      expect(state.cart['P1']!.cantidad, 2);
      await bloc.close();
    });

    test('UpdateCartItemQuantity a 0 elimina el producto del carrito',
        () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [
            _jsonP1(),
            {
              'codigo': 'P2',
              'nombre': 'Agua',
              'precioUnitario': 50.0,
              'stockActual': 20,
              'activo': true,
            },
          ]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 1);
      await _add1(bloc, 'P2', 1);

      final removed = bloc.stream.firstWhere((s) => !s.cart.containsKey('P1'));
      bloc.add(const UpdateCartItemQuantity('P1', 0));
      final state = await removed;

      expect(state.cart.containsKey('P1'), isFalse);
      expect(state.cart.containsKey('P2'), isTrue);
      await bloc.close();
    });

    test('RemoveFromCart elimina el producto del carrito', () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [
            _jsonP1(),
            {
              'codigo': 'P2',
              'nombre': 'Agua',
              'precioUnitario': 50.0,
              'stockActual': 20,
              'activo': true,
            },
          ]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 1);
      await _add1(bloc, 'P2', 1);

      final removed = bloc.stream.firstWhere((s) => !s.cart.containsKey('P1'));
      bloc.add(const RemoveFromCart('P1'));
      final state = await removed;

      expect(state.cart.length, 1);
      expect(state.cart.containsKey('P1'), isFalse);
      await bloc.close();
    });
  });

  group('PosBloc - ConfirmSale (N1)', () {
    test('ConfirmSale sin método de pago emite error', () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 1);

      final err = bloc.stream.firstWhere((s) => s.errorMessage != null);
      bloc.add(const ConfirmSale());
      final state = await err;

      expect(state.errorMessage,
          contains('Seleccione un método de pago y agregue productos'));
      await bloc.close();
    });

    test('ConfirmSale con venta exitosa emite éxito, vacía el carrito y '
        'guarda el snapshot', () async {
      final api = MockPosApi();
      when(() => api.createSale(any())).thenAnswer((_) async {});
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 2);
      final metodo = bloc.stream
          .firstWhere((s) => s.selectedPaymentMethod == 'EFECTIVO');
      bloc.add(const SelectPaymentMethod('EFECTIVO'));
      await metodo;

      final done = bloc.stream.firstWhere((s) => s.successMessage != null);
      bloc.add(const ConfirmSale());
      final state = await done;

      expect(state.successMessage, 'Venta registrada correctamente');
      expect(state.cart, isEmpty);
      expect(state.completedSale, isNotNull);
      expect(state.completedSale!.paymentMethod, 'EFECTIVO');
      expect(state.completedSale!.totalAmount, 300.0);
      verify(() => api.createSale(any())).called(1);
      await bloc.close();
    });

    test('ConfirmSale con error del backend emite errorMessage', () async {
      final api = MockPosApi();
      when(() => api.createSale(any()))
          .thenThrow(Exception('No se pudo registrar la venta'));
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 1);
      final metodo = bloc.stream
          .firstWhere((s) => s.selectedPaymentMethod == 'EFECTIVO');
      bloc.add(const SelectPaymentMethod('EFECTIVO'));
      await metodo;

      final err = bloc.stream.firstWhere((s) => s.errorMessage != null);
      bloc.add(const ConfirmSale());
      final state = await err;

      expect(state.errorMessage, contains('No se pudo registrar la venta'));
      expect(state.cart, isNotEmpty);
      await bloc.close();
    });
  });

  group('PosBloc - productos y stock (N1)', () {
    test('LoadProducts carga el catálogo desde el servicio', () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      final state = await _cargarCatalogo(bloc);

      expect(state.products, hasLength(1));
      expect(state.products.single.codigo, 'P1');
      expect(state.isLoading, isFalse);
      await bloc.close();
    });

    test('LoadProducts con error del backend emite errorMessage', () async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenThrow(Exception('Error de red'));
      final bloc = PosBloc(apiService: api);

      final err = bloc.stream.firstWhere((s) => s.errorMessage != null);
      bloc.add(const LoadProducts());
      final state = await err;

      expect(state.errorMessage, contains('Error de red'));
      await bloc.close();
    });

    test('CreateProduct exitoso emite mensaje de éxito', () async {
      final api = MockPosApi();
      when(() => api.createProduct(any()))
          .thenAnswer((_) async => Product.fromJson(_jsonP1()));
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      final done = bloc.stream.firstWhere((s) => s.successMessage != null);
      bloc.add(const CreateProduct({
        'codigo': 'P1',
        'nombre': 'Café',
        'precioUnitario': 150.0,
        'activo': true,
      }));
      final state = await done;

      expect(state.successMessage, 'Producto guardado con éxito');
      verify(() => api.createProduct(any())).called(1);
      await bloc.close();
    });

    test('CreateProduct con código duplicado (409) emite errorMessage',
        () async {
      final api = MockPosApi();
      when(() => api.createProduct(any()))
          .thenThrow(Exception('El código de producto ya existe'));
      final bloc = PosBloc(apiService: api);

      final err = bloc.stream.firstWhere((s) => s.errorMessage != null);
      bloc.add(const CreateProduct({
        'codigo': 'P1',
        'nombre': 'Duplicado',
        'precioUnitario': 10.0,
        'activo': true,
      }));
      final state = await err;

      expect(state.errorMessage, contains('El código de producto ya existe'));
      verify(() => api.createProduct(any())).called(1);
      await bloc.close();
    });

    test('UpdateProduct con ajuste de stock válido persiste el ajuste',
        () async {
      final api = MockPosApi();
      when(() => api.updateProduct(any(), any()))
          .thenAnswer((_) async => Product.fromJson(_jsonP1()));
      when(() => api.ajustarStock(any(),
              cantidad: any(named: 'cantidad'),
              motivo: any(named: 'motivo')))
          .thenAnswer((_) async => Product.fromJson(_jsonP1()));
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      final done = bloc.stream.firstWhere((s) => s.successMessage != null);
      bloc.add(const UpdateProduct(
        'P1',
        {'nombre': 'Café', 'precioUnitario': 150.0},
        stockAjuste: 5,
        stockMotivo: 'Ajuste manual constatado',
      ));
      final state = await done;

      expect(state.successMessage, 'Producto actualizado con éxito');
      verify(() => api.ajustarStock('P1',
              cantidad: 5, motivo: 'Ajuste manual constatado'))
          .called(1);
      await bloc.close();
    });

    test('UpdateProduct sin ajuste de stock no llama al endpoint /stock',
        () async {
      final api = MockPosApi();
      when(() => api.updateProduct(any(), any()))
          .thenAnswer((_) async => Product.fromJson(_jsonP1()));
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      final bloc = PosBloc(apiService: api);

      final done = bloc.stream.firstWhere((s) => s.successMessage != null);
      bloc.add(const UpdateProduct(
        'P1',
        {'nombre': 'Café', 'precioUnitario': 150.0},
      ));
      final state = await done;

      expect(state.successMessage, 'Producto actualizado con éxito');
      verifyNever(() => api.ajustarStock(any(),
          cantidad: any(named: 'cantidad'),
          motivo: any(named: 'motivo')));
      await bloc.close();
    });
  });
}