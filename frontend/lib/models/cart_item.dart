import 'package:equatable/equatable.dart';

/// D.12: ítem del carrito con precio congelado al momento de agregar.
class CartItem extends Equatable {
  final String codigo;
  final String nombre;
  final double precioUnitario;
  final int cantidad;

  const CartItem({
    required this.codigo,
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
  });

  CartItem copyWith({int? cantidad}) {
    return CartItem(
      codigo: codigo,
      nombre: nombre,
      precioUnitario: precioUnitario,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  double get subtotal => precioUnitario * cantidad;

  @override
  List<Object?> get props => [codigo, nombre, precioUnitario, cantidad];
}
