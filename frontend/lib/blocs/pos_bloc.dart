import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_event.dart';
import 'pos_state.dart';
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
    on<ClearSuccess>((event, emit) => emit(state.copyWith(successMessage: null)));
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _apiService.getProducts();
      final products = data.map((json) => Product.fromJson(json)).toList();
      emit(state.copyWith(products: products, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    if (event.quantity <= 0) return;
    final newCart = Map<String, int>.from(state.cart);
    final currentQty = newCart[event.productCode] ?? 0;
    newCart[event.productCode] = currentQty + event.quantity;
    emit(state.copyWith(cart: newCart));
  }

  void _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<PosState> emit) {
    if (event.newQuantity <= 0) {
      add(RemoveFromCart(event.productCode));
      return;
    }
    final newCart = Map<String, int>.from(state.cart);
    newCart[event.productCode] = event.newQuantity;
    emit(state.copyWith(cart: newCart));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<PosState> emit) {
    final newCart = Map<String, int>.from(state.cart);
    newCart.remove(event.productCode);
    emit(state.copyWith(cart: newCart));
  }

  void _onSelectPaymentMethod(SelectPaymentMethod event, Emitter<PosState> emit) {
    emit(state.copyWith(selectedPaymentMethod: event.method));
  }

  Future<void> _onConfirmSale(ConfirmSale event, Emitter<PosState> emit) async {
    if (state.selectedPaymentMethod == null || state.cart.isEmpty) {
      emit(state.copyWith(errorMessage: 'Seleccione un método de pago y agregue productos'));
      return;
    }

    emit(state.copyWith(isProcessing: true));
    try {
      // Mapeo de método de pago a número (según backend)
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
          'cantidad': entry.value,
        };
      }).toList();

      final saleData = {
        'metodoPago': metodoPagoId,
        'lineas': lineas,
      };

      await _apiService.createSale(saleData);

      // Éxito: limpiar carrito y método de pago, pero mantener productos
      emit(PosState.initial());
      // Recargar productos para actualizar stock desde backend
      add(LoadProducts());
      emit(state.copyWith(successMessage: 'Venta registrada correctamente'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(isProcessing: false));
    }
  }
}