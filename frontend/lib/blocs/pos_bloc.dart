import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import '../models/product.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  PosBloc() : super(PosState.initial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<ConfirmSale>(_onConfirmSale);
  }

  void _onLoadProducts(LoadProducts event, Emitter<PosState> emit) {
    // Datos mock según el contrato
    final mockProducts = [
      Product(codigo: '1001', nombre: 'Arroz Integral 1kg', precioUnitario: 1500.0, stockActual: 25),
      Product(codigo: '1003', nombre: 'Cerveza Brahma', precioUnitario: 3000.0, stockActual: 15),
      Product(codigo: '1005', nombre: 'Carbón 2kg', precioUnitario: 1200.0, stockActual: 8),
      Product(codigo: '1007', nombre: 'Gaseosa 2L', precioUnitario: 1800.0, stockActual: 20),
    ];
    emit(state.copyWith(products: mockProducts));
  }

  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    final product = state.products.firstWhere((p) => p.codigo == event.productCode);
    if (product.stockActual < event.quantity) return; // validación básica
    final newCart = Map<String, int>.from(state.cart);
    final currentQty = newCart[event.productCode] ?? 0;
    newCart[event.productCode] = currentQty + event.quantity;
    emit(state.copyWith(cart: newCart));
  }

  void _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<PosState> emit) {
    final product = state.products.firstWhere((p) => p.codigo == event.productCode);
    if (event.newQuantity <= 0) {
      // Si cantidad es 0 o negativa, eliminamos
      add(RemoveFromCart(event.productCode));
      return;
    }
    if (product.stockActual < event.newQuantity) return;
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

  void _onConfirmSale(ConfirmSale event, Emitter<PosState> emit) {
    // Solo mock: en el maquetado mostramos un diálogo (lo manejaremos en la pantalla)
    // Emitimos un estado de procesamiento para mostrar un loading si se desea
    emit(state.copyWith(isProcessing: true));
    // Simulamos un pequeño delay y luego volvemos a false
    Future.delayed(Duration(milliseconds: 500), () {
      emit(state.copyWith(isProcessing: false));
    });
  }
}