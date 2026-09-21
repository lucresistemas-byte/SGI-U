import 'package:equatable/equatable.dart';
import '../../models/pedido.dart';

abstract class PedidosEvent extends Equatable {
  const PedidosEvent();

  @override
  List<Object?> get props => [];
}

class CargarPedidos extends PedidosEvent {
  final String? query;
  const CargarPedidos({this.query});

  @override
  List<Object?> get props => [query];
}

class BuscarPedidos extends PedidosEvent {
  final String query;
  const BuscarPedidos(this.query);

  @override
  List<Object?> get props => [query];
}

class CrearPedidoEvent extends PedidosEvent {
  final Map<String, dynamic> data;
  const CrearPedidoEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class RegistrarAbonoEvent extends PedidosEvent {
  final int pedidoId;
  final double monto;
  final String? metodoPago;
  final String? nota;

  const RegistrarAbonoEvent({
    required this.pedidoId,
    required this.monto,
    this.metodoPago,
    this.nota,
  });

  @override
  List<Object?> get props => [pedidoId, monto, metodoPago, nota];
}

class CancelarPedidoEvent extends PedidosEvent {
  final int pedidoId;
  const CancelarPedidoEvent(this.pedidoId);

  @override
  List<Object?> get props => [pedidoId];
}

class SeleccionarPedido extends PedidosEvent {
  final Pedido? pedido;
  const SeleccionarPedido(this.pedido);

  @override
  List<Object?> get props => [pedido];
}

class LimpiarMensajesPedidos extends PedidosEvent {
  const LimpiarMensajesPedidos();
}
