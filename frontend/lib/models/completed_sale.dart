import 'package:equatable/equatable.dart';
import 'cart_item.dart';

/// Snapshot de una venta completada, usado por D.7.1/D.7.2 para generar
/// el ticket PDF después de que el carrito se limpia.
class CompletedSale extends Equatable {
  final List<CartItem> items;
  final String paymentMethod;
  final double totalAmount;
  final DateTime timestamp;

  const CompletedSale({
    required this.items,
    required this.paymentMethod,
    required this.totalAmount,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [items, paymentMethod, totalAmount, timestamp];
}
