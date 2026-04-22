import 'package:equatable/equatable.dart';
import '../models/product.dart';

class PosState extends Equatable {
  final List<Product> products;
  final Map<String, int> cart; // productCode -> quantity
  final String? selectedPaymentMethod;
  final bool isProcessing;

  const PosState({
    required this.products,
    required this.cart,
    this.selectedPaymentMethod,
    this.isProcessing = false,
  });

  factory PosState.initial() {
    return PosState(
      products: [],
      cart: {},
      selectedPaymentMethod: null,
      isProcessing: false,
    );
  }

  PosState copyWith({
    List<Product>? products,
    Map<String, int>? cart,
    String? selectedPaymentMethod,
    bool? isProcessing,
  }) {
    return PosState(
      products: products ?? this.products,
      cart: cart ?? this.cart,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  double get totalAmount {
    double total = 0.0;
    for (var entry in cart.entries) {
      final product = products.firstWhere(
            (p) => p.codigo == entry.key,
        orElse: () => Product(codigo: '', nombre: '', precioUnitario: 0, stockActual: 0),
      );
      total += product.precioUnitario * entry.value;
    }
    return total;
  }

  @override
  List<Object?> get props => [products, cart, selectedPaymentMethod, isProcessing];
}