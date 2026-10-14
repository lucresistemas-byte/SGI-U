import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgi_u_frontend/blocs/pos_bloc.dart';
import 'package:sgi_u_frontend/blocs/pos_event.dart';
import 'package:sgi_u_frontend/blocs/pos_state.dart';
import 'package:sgi_u_frontend/models/metodo_pago.dart';
import 'package:sgi_u_frontend/models/product.dart';
import 'package:sgi_u_frontend/services/api_service.dart';

class MockPosApi extends Mock implements PosApi {}

class _MockApiService extends Mock implements ApiService {}

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

  group('PosBloc - cobro con pagos mixtos (D.4.1/D.4.2)', () {
    const efectivo = MetodoPago(id: 1, nombre: 'Efectivo', fijo: true, orden: 1);
    const tarjeta = MetodoPago(id: 3, nombre: 'Tarjeta', orden: 2);

    /// Catálogo con Café a $150 y 2 en el carrito: total $300.
    Future<(PosBloc, MockPosApi)> conCarrito() async {
      final api = MockPosApi();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      when(() => api.createSale(any())).thenAnswer((_) async {});
      final bloc = PosBloc(apiService: api, cargarMetodosPago: () async => const [efectivo, tarjeta]);
      await _cargarCatalogo(bloc);
      await _add1(bloc, 'P1', 2);
      return (bloc, api);
    }

    Future<PosState> despues(PosBloc bloc, PosEvent evento, bool Function(PosState) listo) {
      final f = bloc.stream.firstWhere(listo);
      bloc.add(evento);
      return f;
    }

    Map<String, dynamic> enviado(MockPosApi api) =>
        verify(() => api.createSale(captureAny())).captured.single as Map<String, dynamic>;

    test('sin pagos no se confirma (y no llama al backend)', () async {
      final (bloc, api) = await conCarrito();

      final s = await despues(bloc, const ConfirmSale(), (s) => s.errorMessage != null);

      expect(s.errorMessage, 'Los pagos no cubren el total: faltan \$300.00.');
      expect(s.cobroCubierto, isFalse);
      verifyNever(() => api.createSale(any()));
      await bloc.close();
    });

    test('camino rápido: un toque paga todo con un método', () async {
      final (bloc, api) = await conCarrito();

      final s = await despues(bloc, const PagarRestante(1), (s) => s.pagos.isNotEmpty);
      expect(s.cobroCubierto, isTrue);
      expect(s.restante, 0);

      final ok = await despues(bloc, const ConfirmSale(), (s) => s.successMessage != null);
      expect(ok.successMessage, 'Venta registrada correctamente');
      expect(ok.cart, isEmpty);
      expect(ok.pagos, isEmpty);
      expect(ok.completedSale!.paymentMethod, 'Efectivo');
      expect(ok.completedSale!.totalAmount, 300.0);
      final venta = enviado(api);
      expect(venta['pagos'], [
        {'metodoPagoId': 1, 'monto': 300.0}
      ]);
      // Etapa 4: cada línea lleva el precio congelado al agregarla al carrito.
      expect(venta['lineas'], [
        {'codigoProducto': 'P1', 'cantidad': 2, 'precioUnitario': 150.0}
      ]);
      await bloc.close();
    });

    test('mixto efectivo + tarjeta: una línea por método', () async {
      final (bloc, api) = await conCarrito();

      var s = await despues(bloc, const AgregarPago(3, 100), (s) => s.pagos.length == 1);
      expect(s.restante, 200.0);
      expect(s.cobroCubierto, isFalse);
      s = await despues(bloc, const PagarRestante(1), (s) => s.pagos.length == 2);
      expect(s.cobroCubierto, isTrue);

      final ok = await despues(bloc, const ConfirmSale(), (s) => s.successMessage != null);
      expect(ok.completedSale!.paymentMethod, 'Tarjeta + Efectivo');
      expect(ok.completedSale!.pagos.map((p) => p.monto), [100.0, 200.0]);
      expect(enviado(api)['pagos'], [
        {'metodoPagoId': 3, 'monto': 100.0},
        {'metodoPagoId': 1, 'monto': 200.0},
      ]);
      await bloc.close();
    });

    test('efectivo de más: muestra el vuelto y envía lo entregado', () async {
      final (bloc, api) = await conCarrito();

      final s = await despues(bloc, const AgregarPago(1, 500), (s) => s.pagos.isNotEmpty);
      expect(s.vuelto, 200.0);
      expect(s.restante, 0);
      expect(s.cobroCubierto, isTrue);

      final ok = await despues(bloc, const ConfirmSale(), (s) => s.successMessage != null);
      expect(ok.successMessage, 'Venta registrada correctamente. Vuelto: \$200.00');
      expect(ok.completedSale!.vuelto, 200.0);
      expect(enviado(api)['pagos'], [
        {'metodoPagoId': 1, 'monto': 500.0}
      ]);
      await bloc.close();
    });

    test('un método que no es efectivo no puede pasarse de lo que falta', () async {
      final (bloc, _) = await conCarrito();
      await despues(bloc, const AgregarPago(1, 100), (s) => s.pagos.isNotEmpty);

      final s = await despues(bloc, const AgregarPago(3, 250), (s) => s.errorMessage != null);

      expect(s.errorMessage,
          'Con Tarjeta no se puede pagar más de lo que falta (\$200.00). Solo el efectivo tiene vuelto.');
      expect(s.pagos.map((p) => p.metodo.id), [1]);
      await bloc.close();
    });

    test('el mismo método suma en su línea y se puede quitar', () async {
      final (bloc, _) = await conCarrito();
      await despues(bloc, const AgregarPago(1, 100), (s) => s.pagos.isNotEmpty);
      var s = await despues(bloc, const AgregarPago(1, 50), (s) => s.totalPagado == 150);
      expect(s.pagos, hasLength(1));

      s = await despues(bloc, const QuitarPago(0), (s) => s.pagos.isEmpty);
      expect(s.restante, 300.0);
      await bloc.close();
    });

    test('si cambia el carrito, el cobro se arma de nuevo', () async {
      final (bloc, _) = await conCarrito();
      await despues(bloc, const PagarRestante(3), (s) => s.pagos.isNotEmpty);

      final s = await despues(bloc, const AddToCart('P1', 1), (s) => s.cart['P1']!.cantidad == 3);

      expect(s.pagos, isEmpty);
      expect(s.cobroCubierto, isFalse);
      await bloc.close();
    });

    test('error del backend: conserva carrito y pagos para reintentar', () async {
      final (bloc, api) = await conCarrito();
      when(() => api.createSale(any())).thenThrow(Exception('No se pudo registrar la venta'));
      await despues(bloc, const PagarRestante(1), (s) => s.pagos.isNotEmpty);

      final s = await despues(bloc, const ConfirmSale(), (s) => s.errorMessage != null);

      expect(s.errorMessage, contains('No se pudo registrar la venta'));
      expect(s.cart, isNotEmpty);
      expect(s.pagos, isNotEmpty);
      expect(s.isProcessing, isFalse);
      await bloc.close();
    });

    test('con la API real, trae solo los métodos activos', () async {
      final api = _MockApiService();
      when(() => api.getProducts()).thenAnswer((_) async => [_jsonP1()]);
      when(() => api.getMetodosPago()).thenAnswer((_) async => const [efectivo]);
      final bloc = PosBloc(apiService: api);

      final s = await _cargarCatalogo(bloc);

      expect(s.metodosPago, [efectivo]);
      verify(() => api.getMetodosPago()).called(1);
      verifyNever(() => api.getMetodosPago(incluirInactivos: true));
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