import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import '../models/cart_item.dart';
import '../models/completed_sale.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final ApiService _apiService = ApiService();

  PosBloc() : super(PosState.initial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<ConfirmSale>(_onConfirmSale);
    on<ClearError>((event, emit) => emit(state.copyWith(errorMessage: null)));
    on<ClearSuccess>((event, emit) =>
        emit(state.copyWith(successMessage: null, completedSale: null)));
    on<ClearSelection>((event, emit) =>
        emit(PosState.initial().copyWith(products: state.products)));

    on<CreateProduct>((event, emit) async {
      emit(state.copyWith(
          isLoading: true, errorMessage: null, successMessage: null));
      try {
        await _apiService.createProduct(event.productData);
        add(LoadProducts());
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
        add(LoadProducts());
        emit(state.copyWith(
            isLoading: false,
            successMessage: 'Producto actualizado con éxito'));
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _apiService.getProducts();
      final products = data.map((json) => Product.fromJson(json)).toList();
      emit(state.copyWith(products: products, isLoading: false));
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

    emit(state.copyWith(cart: newCart));
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
    emit(state.copyWith(cart: newCart));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<PosState> emit) {
    final newCart = Map<String, CartItem>.from(state.cart);
    newCart.remove(event.productCode);
    emit(state.copyWith(cart: newCart));
  }

  void _onSelectPaymentMethod(
      SelectPaymentMethod event, Emitter<PosState> emit) {
    emit(state.copyWith(selectedPaymentMethod: event.method));
  }

  /// D.12/D.7.1: captura snapshot de la venta ANTES de limpiar el carrito.
  Future<void> _onConfirmSale(ConfirmSale event, Emitter<PosState> emit) async {
    if (state.selectedPaymentMethod == null || state.cart.isEmpty) {
      emit(state.copyWith(
          errorMessage: 'Seleccione un método de pago y agregue productos'));
      return;
    }

    // D.12: snapshot con precio congelado para el ticket (D.7.1/D.7.2)
    final saleSnapshot = CompletedSale(
      items: state.cart.values.toList(),
      paymentMethod: state.selectedPaymentMethod!,
      totalAmount: state.totalAmount,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(isProcessing: true));
    try {
      int metodoPagoId;
      switch (state.selectedPaymentMethod!) {
        case 'EFECTIVO':
          metodoPagoId = 1;
          break;
        case 'MERCADO_PAGO':
          metodoPagoId = 2;
          break;
        default:
          metodoPagoId = 1;
      }

      final lineas = state.cart.entries.map((entry) {
        return {
          'codigoProducto': entry.key,
          'cantidad': entry.value.cantidad,
        };
      }).toList();

      final saleData = {
        'metodoPago': metodoPagoId,
        'lineas': lineas,
      };

      await _apiService.createSale(saleData);

      // D.12: limpiar carrito conservando productos, snapshot de venta y mensaje de éxito.
      // Un solo emit evita re-triggers del BlocListener.
      emit(PosState.initial().copyWith(
        products: state.products,
        completedSale: saleSnapshot,
        successMessage: 'Venta registrada correctamente',
      ));
      add(LoadProducts());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
