import 'package:equatable/equatable.dart';
import 'metodo_pago.dart';

/// Una línea del cobro del POS: método + monto. En efectivo, el monto es lo
/// que entrega el cliente (puede superar lo que falta: la diferencia es el
/// vuelto).
class LineaPago extends Equatable {
  final MetodoPago metodo;
  final double monto;

  const LineaPago({required this.metodo, required this.monto});

  LineaPago conMonto(double nuevo) => LineaPago(metodo: metodo, monto: nuevo);

  @override
  List<Object?> get props => [metodo.id, monto];
}
