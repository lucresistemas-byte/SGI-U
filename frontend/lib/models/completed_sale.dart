import 'package:equatable/equatable.dart';
import 'cart_item.dart';
import 'linea_pago.dart';

/// Snapshot de una venta completada, usado por D.7.1/D.7.2 para generar
/// el ticket PDF después de que el carrito se limpia.
class CompletedSale extends Equatable {
  final List<CartItem> items;

  /// Resumen de los métodos (p. ej. "Efectivo + Tarjeta").
  final String paymentMethod;
  final double totalAmount;
  final DateTime timestamp;

  /// Lo cobrado con cada método (pago mixto) y el vuelto en efectivo.
  final List<LineaPago> pagos;
  final double vuelto;

  const CompletedSale({
    required this.items,
    required this.paymentMethod,
    required this.totalAmount,
    required this.timestamp,
    this.pagos = const [],
    this.vuelto = 0,
  });

  @override
  List<Object?> get props => [items, paymentMethod, totalAmount, timestamp, pagos, vuelto];
}
