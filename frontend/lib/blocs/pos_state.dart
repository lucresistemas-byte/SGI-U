import 'package:equatable/equatable.dart';
import '../models/cart_item.dart';
import '../models/completed_sale.dart';
import '../models/product.dart';

const Object _unset = Object();

class PosState extends Equatable {
  final List<Product> products;
  final Map<String, CartItem> cart;
  final String? selectedPaymentMethod;
  final bool isProcessing;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final CompletedSale? completedSale;

  const PosState({
    required this.products,
    required this.cart,
    this.selectedPaymentMethod,
    this.isProcessing = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.completedSale,
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
      completedSale: null,
    );
  }

  PosState copyWith({
    List<Product>? products,
    Map<String, CartItem>? cart,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
    Object? completedSale = _unset,
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
      completedSale: identical(completedSale, _unset)
          ? this.completedSale
          : completedSale as CompletedSale?,
    );
  }

  /// D.12: total usando precio congelado de CartItem.
  double get totalAmount {
    double total = 0.0;
    for (var item in cart.values) {
      total += item.precioUnitario * item.cantidad;
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
        completedSale,
      ];
}
