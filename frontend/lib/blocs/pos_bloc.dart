import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import '../models/cart_item.dart';
import '../models/completed_sale.dart';
import '../models/linea_pago.dart';
import '../models/metodo_pago.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/numeros.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosApi _apiService;

  /// A2: token de idempotencia del cobro en curso. Se genera al confirmar la
  /// venta y se conserva si el cobro falla, para que un reintento (del
  /// usuario o de la red) no registre la venta dos veces.
  String? _tokenVentaPendiente;

  /// Métodos de pago activos. Por defecto los de la API real; con otra
  /// PosApi (tests) no hay métodos salvo que se indique un cargador.
  final Future<List<MetodoPago>> Function() _cargarMetodosPago;

  PosBloc({PosApi? apiService, Future<List<MetodoPago>> Function()? cargarMetodosPago})
      : _apiService = apiService ?? ApiService(),
        _cargarMetodosPago = cargarMetodosPago ??
            ((apiService ?? ApiService()) is ApiService
                ? () => ((apiService ?? ApiService()) as ApiService).getMetodosPago()
                : () async => const <MetodoPago>[]),
        super(PosState.initial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<AgregarPago>(_onAgregarPago);
    on<PagarRestante>((event, emit) {
      if (state.restante <= 0) return;
      _onAgregarPago(AgregarPago(event.metodoPagoId, state.restante), emit);
    });
    on<QuitarPago>((event, emit) {
      if (event.indice < 0 || event.indice >= state.pagos.length) return;
      emit(state.copyWith(pagos: [...state.pagos]..removeAt(event.indice)));
    });
    on<ConfirmSale>(_onConfirmSale);
    on<ClearError>((event, emit) => emit(state.copyWith(errorMessage: null)));
    on<ClearSuccess>((event, emit) =>
        emit(state.copyWith(successMessage: null, completedSale: null)));
    on<ClearSelection>((event, emit) {
      _descartarTokenVenta();
      emit(PosState.initial()
          .copyWith(products: state.products, metodosPago: state.metodosPago));
    });

    on<CreateProduct>((event, emit) async {
      emit(state.copyWith(
          isLoading: true, errorMessage: null, successMessage: null));
      try {
        await _apiService.createProduct(event.productData);
        add(const LoadProducts());
        emit(state.copyWith(
            isLoading: false, successMessage: 'Producto guardado con éxito'));
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });

    on<UpdateProduct>((event, emit) async {
      emit(state.copyWith(
          isLoading: true, errorMessage: null, successMessage: null));
      try {
        await _apiService.updateProduct(event.codigo, event.productData);

        // Ajuste de stock en edición: se persiste con el endpoint dedicado.
        final ajuste = event.stockAjuste;
        if (ajuste != null && ajuste != 0) {
          await _apiService.ajustarStock(
            event.codigo,
            cantidad: ajuste,
            motivo: event.stockMotivo ?? 'Ajuste manual',
            tipo: event.stockTipo,
          );
        }

        add(const LoadProducts());
        emit(state.copyWith(
            isLoading: false,
            successMessage: 'Producto actualizado con éxito'));
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });

    on<FilterByCategoryEvent>((event, emit) {
      final category = (event.category == null || event.category == 'Todas')
          ? null
          : event.category;
      emit(state.copyWith(selectedCategory: category));
    });

    on<SearchProductsEvent>((event, emit) {
      emit(state.copyWith(searchQuery: event.query));
    });
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _apiService.getProducts();
      final products = data.map((json) => Product.fromJson(json)).toList();
      // Se espera antes de leer `state`: si no, se reemitiría un estado viejo.
      final metodosPago = await _metodosActivos();
      emit(state.copyWith(products: products, isLoading: false, metodosPago: metodosPago));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// D.12: captura precio y nombre del producto al agregar al carrito.
  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    if (event.quantity <= 0) return;

    final product = state.products.firstWhere(
      (p) => p.codigo == event.productCode,
      orElse: () => Product(
          codigo: '', nombre: '', precioUnitario: 0, stockActual: 0),
    );

    final newCart = Map<String, CartItem>.from(state.cart);
    final existing = newCart[event.productCode];

    if (existing != null) {
      newCart[event.productCode] =
          existing.copyWith(cantidad: existing.cantidad + event.quantity);
    } else {
      newCart[event.productCode] = CartItem(
        codigo: product.codigo,
        nombre: product.nombre,
        precioUnitario: product.precioUnitario,
        cantidad: event.quantity,
      );
    }

    // Si cambia el carrito, cambia el total: el cobro se arma de nuevo.
    _descartarTokenVenta();
    emit(state.copyWith(cart: newCart, pagos: const []));
  }

  /// D.12: actualiza cantidad preservando precio congelado.
  void _onUpdateCartItemQuantity(
      UpdateCartItemQuantity event, Emitter<PosState> emit) {
    if (event.newQuantity <= 0) {
      add(RemoveFromCart(event.productCode));
      return;
    }
    final newCart = Map<String, CartItem>.from(state.cart);
    final existing = newCart[event.productCode];
    if (existing != null) {
      newCart[event.productCode] = existing.copyWith(cantidad: event.newQuantity);
    }
    _descartarTokenVenta();
    emit(state.copyWith(cart: newCart, pagos: const []));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<PosState> emit) {
    final newCart = Map<String, CartItem>.from(state.cart);
    newCart.remove(event.productCode);
    _descartarTokenVenta();
    emit(state.copyWith(cart: newCart, pagos: const []));
  }

  /// Activos, en el orden de Configuración; si fallan, el POS sigue
  /// mostrando los productos (y avisa al intentar cobrar).
  Future<List<MetodoPago>> _metodosActivos() async {
    try {
      return await _cargarMetodosPago();
    } catch (_) {
      return state.metodosPago;
    }
  }

  static String _pesos(double v) => formatPesos(v);

  /// A2: token aleatorio de idempotencia (32 hex) para un cobro.
  static String _nuevoTokenVenta() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Un cambio del carrito o del cobro es una venta distinta: el token de
  /// idempotencia del intento anterior ya no corresponde.
  void _descartarTokenVenta() {
    _tokenVentaPendiente = null;
  }

  /// D.4.1/D.4.2: una línea más del cobro. Un método que no es efectivo no
  /// puede pasarse de lo que falta; el efectivo sí (vuelto).
  void _onAgregarPago(AgregarPago event, Emitter<PosState> emit) {
    if (state.cart.isEmpty) return;
    final metodo = state.metodosPago.where((m) => m.id == event.metodoPagoId).firstOrNull;
    if (metodo == null) return;
    final monto = (event.monto * 100).roundToDouble() / 100;
    if (monto <= 0) {
      emit(state.copyWith(errorMessage: 'Ingrese un monto mayor a cero.'));
      return;
    }
    final indice = state.pagos.indexWhere((p) => p.metodo.id == metodo.id);
    final anterior = indice >= 0 ? state.pagos[indice].monto : 0.0;
    // Lo que falta sin contar lo que ya se cargó con este método.
    final faltaParaEste = state.restante + anterior;
    if (!metodo.esEfectivo && anterior + monto > faltaParaEste + 0.001) {
      emit(state.copyWith(
          errorMessage: 'Con ${metodo.nombre} no se puede pagar más de lo que falta '
              '(${_pesos(faltaParaEste - anterior)}). Solo el efectivo tiene vuelto.'));
      return;
    }
    final pagos = [...state.pagos];
    if (indice >= 0) {
      pagos[indice] = pagos[indice].conMonto(anterior + monto);
    } else {
      pagos.add(LineaPago(metodo: metodo, monto: monto));
    }
    emit(state.copyWith(pagos: pagos));
  }

  /// D.12/D.7.1: captura snapshot de la venta ANTES de limpiar el carrito.
  Future<void> _onConfirmSale(ConfirmSale event, Emitter<PosState> emit) async {
    if (state.cart.isEmpty) {
      emit(state.copyWith(errorMessage: 'Agregue productos antes de cobrar.'));
      return;
    }
    if (!state.cobroCubierto) {
      emit(state.copyWith(
          errorMessage: 'Los pagos no cubren el total: faltan ${_pesos(state.restante)}.'));
      return;
    }

    // D.12: snapshot con precio congelado para el ticket (D.7.1/D.7.2)
    final saleSnapshot = CompletedSale(
      items: state.cart.values.toList(),
      paymentMethod: state.pagos.map((p) => p.metodo.nombre).join(' + '),
      totalAmount: state.totalAmount,
      timestamp: DateTime.now(),
      pagos: state.pagos,
      vuelto: state.vuelto,
    );

    emit(state.copyWith(isProcessing: true));
    try {
      final lineas = state.cart.entries.map((entry) {
        return {
          'codigoProducto': entry.key,
          'cantidad': entry.value.cantidad,
          // Precio congelado al agregar al carrito: si después cambió, se respeta.
          'precioUnitario': entry.value.precioUnitario,
        };
      }).toList();

      // En efectivo va lo que entregó el cliente: el backend descuenta el
      // vuelto y registra solo lo que corresponde a la venta.
      // A2: tokenIdempotencia evita la doble venta si el cobro se reintenta.
      _tokenVentaPendiente ??= _nuevoTokenVenta();
      final saleData = {
        'lineas': lineas,
        'pagos': [
          for (final p in state.pagos) {'metodoPagoId': p.metodo.id, 'monto': p.monto},
        ],
        'tokenIdempotencia': _tokenVentaPendiente,
      };

      await _apiService.createSale(saleData);
      _tokenVentaPendiente = null;

      // D.12: limpiar carrito conservando productos, snapshot de venta y mensaje de éxito.
      // Un solo emit evita re-triggers del BlocListener.
      emit(PosState.initial().copyWith(
        products: state.products,
        metodosPago: state.metodosPago,
        completedSale: saleSnapshot,
        successMessage: state.vuelto > 0
            ? 'Venta registrada correctamente. Vuelto: ${_pesos(state.vuelto)}'
            : 'Venta registrada correctamente',
      ));
      add(const LoadProducts());
    } catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.toString()));
    }
  }
}
