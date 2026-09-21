import 'package:equatable/equatable.dart';
import '../../models/insumo.dart';
import '../../models/receta.dart';

abstract class RecetasEvent extends Equatable {
  const RecetasEvent();

  @override
  List<Object?> get props => [];
}

class CargarRecetas extends RecetasEvent {
  const CargarRecetas();
}

class CargarDatosAuxiliaresReceta extends RecetasEvent {
  const CargarDatosAuxiliaresReceta();
}

class IniciarNuevaReceta extends RecetasEvent {
  final String? defaultProductoCodigo;
  final String? defaultProductoNombre;

  const IniciarNuevaReceta({
    this.defaultProductoCodigo,
    this.defaultProductoNombre,
  });

  @override
  List<Object?> get props => [defaultProductoCodigo, defaultProductoNombre];
}

class EditarReceta extends RecetasEvent {
  final Receta receta;

  const EditarReceta(this.receta);

  @override
  List<Object?> get props => [receta];
}

class CambiarProductoReceta extends RecetasEvent {
  final String codigo;
  final String nombre;

  const CambiarProductoReceta({required this.codigo, required this.nombre});

  @override
  List<Object?> get props => [codigo, nombre];
}

class CambiarNombreReceta extends RecetasEvent {
  final String nombre;

  const CambiarNombreReceta(this.nombre);

  @override
  List<Object?> get props => [nombre];
}

class CambiarDescripcionReceta extends RecetasEvent {
  final String descripcion;

  const CambiarDescripcionReceta(this.descripcion);

  @override
  List<Object?> get props => [descripcion];
}

class CambiarCostosAdicionales extends RecetasEvent {
  final double costosAdicionales;

  const CambiarCostosAdicionales(this.costosAdicionales);

  @override
  List<Object?> get props => [costosAdicionales];
}

class AgregarFilaInsumo extends RecetasEvent {
  final Insumo insumo;
  final double cantidad;

  const AgregarFilaInsumo({
    required this.insumo,
    this.cantidad = 1.0,
  });

  @override
  List<Object?> get props => [insumo, cantidad];
}

class RemoverFilaInsumo extends RecetasEvent {
  final int index;

  const RemoverFilaInsumo(this.index);

  @override
  List<Object?> get props => [index];
}

class ActualizarCantidadFilaInsumo extends RecetasEvent {
  final int index;
  final double cantidad;

  const ActualizarCantidadFilaInsumo({
    required this.index,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [index, cantidad];
}

class GuardarReceta extends RecetasEvent {
  const GuardarReceta();
}

class EliminarReceta extends RecetasEvent {
  final int id;

  const EliminarReceta(this.id);

  @override
  List<Object?> get props => [id];
}
