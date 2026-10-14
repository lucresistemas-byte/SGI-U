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
  /// En [unidad]: una de la familia, PRESENTACION o UNIDAD_VENTA (null = la
  /// unidad para mostrar).
  final double cantidad;
  final String? unidad;
  final String motivo;

  const AjustarStockInsumoEvent({
    required this.id,
    required this.cantidad,
    this.unidad,
    required this.motivo,
  });

  @override
  List<Object?> get props => [id, cantidad, unidad, motivo];
}

/// Activa o desactiva un insumo (los insumos no se eliminan).
class CambiarEstadoInsumoEvent extends InsumosEvent {
  final int id;
  final bool activo;

  const CambiarEstadoInsumoEvent(this.id, {required this.activo});

  @override
  List<Object?> get props => [id, activo];
}
