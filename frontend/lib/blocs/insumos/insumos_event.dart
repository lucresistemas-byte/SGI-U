import 'package:equatable/equatable.dart';

abstract class InsumosEvent extends Equatable {
  const InsumosEvent();

  @override
  List<Object?> get props => [];
}

class CargarInsumos extends InsumosEvent {
  const CargarInsumos();
}

class FiltrarInsumos extends InsumosEvent {
  final String query;
  const FiltrarInsumos(this.query);

  @override
  List<Object?> get props => [query];
}

class CrearInsumoEvent extends InsumosEvent {
  final Map<String, dynamic> data;
  const CrearInsumoEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class ActualizarInsumoEvent extends InsumosEvent {
  final int id;
  final Map<String, dynamic> data;
  const ActualizarInsumoEvent(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class AjustarStockInsumoEvent extends InsumosEvent {
  final int id;
  final int cantidad;
  final String motivo;

  const AjustarStockInsumoEvent({
    required this.id,
    required this.cantidad,
    required this.motivo,
  });

  @override
  List<Object?> get props => [id, cantidad, motivo];
}
