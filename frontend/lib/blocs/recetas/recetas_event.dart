import 'package:equatable/equatable.dart';
import '../../models/insumo.dart';
import '../../models/receta.dart';
import '../../models/unidad_medida.dart';

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

  /// Por defecto, la unidad base de la familia (la más chica).
  final UnidadMedida? unidad;

  const AgregarFilaInsumo({
    required this.insumo,
    this.cantidad = 1.0,
    this.unidad,
  });

  @override
  List<Object?> get props => [insumo, cantidad, unidad];
}

/// Agrega una fila vacía: el usuario elige el insumo y escribe la cantidad.
class AgregarFilaVacia extends RecetasEvent {
  const AgregarFilaVacia();
}

/// Cambia el insumo de una fila en su lugar, conservando la cantidad.
class CambiarInsumoFila extends RecetasEvent {
  final int index;
  final Insumo insumo;

  const CambiarInsumoFila({required this.index, required this.insumo});

  @override
  List<Object?> get props => [index, insumo];
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

/// Los mensajes ya se mostraron: se limpian para que no se repitan.
class LimpiarMensajesRecetas extends RecetasEvent {
  const LimpiarMensajesRecetas();
}

/// Al crear: usar un producto elaborado existente o crear uno nuevo.
class CambiarModoProductoReceta extends RecetasEvent {
  final bool productoNuevo;

  const CambiarModoProductoReceta({required this.productoNuevo});

  @override
  List<Object?> get props => [productoNuevo];
}

/// Datos del producto elaborado que se crea junto con la receta. Los campos
/// en null no cambian; [quitarCategoria] deja la categoría vacía.
/// Crea una categoría desde el armador y la deja elegida para el producto nuevo.
class CrearCategoriaReceta extends RecetasEvent {
  final String nombre;
  const CrearCategoriaReceta(this.nombre);

  @override
  List<Object?> get props => [nombre];
}

class ActualizarProductoNuevoReceta extends RecetasEvent {
  final String? nombre;
  final int? categoriaId;
  final bool quitarCategoria;
  final double? porcentajeGanancia;
  final bool? preparacionBase;

  const ActualizarProductoNuevoReceta({
    this.nombre,
    this.categoriaId,
    this.quitarCategoria = false,
    this.porcentajeGanancia,
    this.preparacionBase,
  });

  @override
  List<Object?> get props =>
      [nombre, categoriaId, quitarCategoria, porcentajeGanancia, preparacionBase];
}

/// Unidad de una fila (solo unidades de la familia del insumo).
class CambiarUnidadFila extends RecetasEvent {
  final int index;
  final UnidadMedida unidad;
  const CambiarUnidadFila({required this.index, required this.unidad});

  @override
  List<Object?> get props => [index, unidad];
}

class CambiarRinde extends RecetasEvent {
  /// null = vacío.
  final double? rinde;
  const CambiarRinde(this.rinde);

  @override
  List<Object?> get props => [rinde];
}

class CambiarRindeUnidad extends RecetasEvent {
  final String rindeUnidad;
  const CambiarRindeUnidad(this.rindeUnidad);

  @override
  List<Object?> get props => [rindeUnidad];
}
