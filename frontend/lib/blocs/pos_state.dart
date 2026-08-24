import 'package:equatable/equatable.dart';
import '../models/product.dart';

/// Sentinel para distinguir "no se pasó el parámetro" de "se pasó null".
/// Permite que errorMessage/successMessage se preserven por defecto en
/// copyWith y solo se limpien cuando se pasan explícitamente como null.
const Object _unset = Object();

class PosState extends Equatable {
  final List<Product> products;
  final Map<String, int> cart;
  final String? selectedPaymentMethod;
  final bool isProcessing;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PosState({
    required this.products,
    required this.cart,
    this.selectedPaymentMethod,
    this.isProcessing = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  factory PosState.initial() {
    return const PosState(
      products: [],
      cart: {},
      selectedPaymentMethod: null,
      isProcessing: false,
      isLoading: false,
      errorMessage: null,
      successMessage: null,
    );
  }

  PosState copyWith({
    List<Product>? products,
    Map<String, int>? cart,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
  }) {
    return PosState(
      products: products ?? this.products,
      cart: cart ?? this.cart,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
    );
  }

  double get totalAmount {
    double total = 0.0;
    for (var entry in cart.entries) {
      final product = products.firstWhere(
        (p) => p.codigo == entry.key,
        orElse: () =>
            Product(codigo: '', nombre: '', precioUnitario: 0, stockActual: 0),
      );
      total += product.precioUnitario * entry.value;
    }
    return total;
  }

  @override
  List<Object?> get props => [
        products,
        cart,
        selectedPaymentMethod,
        isProcessing,
        isLoading,
        errorMessage,
        successMessage,
      ];
}
