import 'package:equatable/equatable.dart';
import '../../models/categoria.dart';
import '../../models/insumo.dart';
import '../../models/product.dart';
import '../../models/receta.dart';
import '../../models/receta_detalle.dart';

class RecetasState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<Receta> recetas;
  final List<Insumo> availableInsumos;
  final List<Product> availableProductos;
  final List<Categoria> availableCategorias;

  /// Al crear: true = la receta crea un producto elaborado nuevo.
  final bool usarProductoNuevo;

  /// Al editar: false = el producto de la receta está desactivado.
  final bool productoEditadoActivo;
  final String nuevoProductoNombre;
  final String nuevoProductoCodigo;
  final int? nuevoProductoCategoriaId;
  final double? nuevoProductoPorcentaje;
  final bool nuevoProductoPreparacionBase;

  // Editor draft
  final int? editingRecetaId;
  final String selectedProductoCodigo;
  final String selectedProductoNombre;
  final String nombre;
  final String descripcion;
  final double costosAdicionales;
  final List<RecetaDetalle> detalles;
  final double costoTotal;

  const RecetasState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.recetas = const [],
    this.availableInsumos = const [],
    this.availableProductos = const [],
    this.availableCategorias = const [],
    this.usarProductoNuevo = false,
    this.productoEditadoActivo = true,
    this.nuevoProductoNombre = '',
    this.nuevoProductoCodigo = '',
    this.nuevoProductoCategoriaId,
    this.nuevoProductoPorcentaje,
    this.nuevoProductoPreparacionBase = false,
    this.editingRecetaId,
    this.selectedProductoCodigo = '',
    this.selectedProductoNombre = '',
    this.nombre = '',
    this.descripcion = '',
    this.costosAdicionales = 0.0,
    this.detalles = const [],
    this.costoTotal = 0.0,
  });

  factory RecetasState.initial() => const RecetasState();

  /// Productos que pueden recibir una receta nueva: elaborados activos que
  /// todavía no tienen receta (la reventa no lleva receta).
  List<Product> get elaboradosSinReceta {
    final conReceta = recetas.map((r) => r.espProductoCodigo).toSet();
    return availableProductos
        .where((p) => p.esElaborado && p.activo && !conReceta.contains(p.codigo))
        .toList();
  }

  static const mensajeFilasIncompletas =
      'Complete el insumo y la cantidad de todas las filas para guardar la receta.';

  /// Alguna fila sin insumo elegido o sin cantidad.
  bool get hayFilasIncompletas => detalles.any((d) => !d.completa);

  bool get creaProductoNuevo => editingRecetaId == null && usarProductoNuevo;

  bool get isFormValid {
    if (creaProductoNuevo) {
      if (nuevoProductoNombre.trim().isEmpty) return false;
      if (nuevoProductoCategoriaId == null) return false;
    } else if (selectedProductoCodigo.trim().isEmpty) {
      return false;
    }
    if (nombre.trim().isEmpty) return false;
    if (detalles.isEmpty) return false;
    for (final d in detalles) {
      final hasValidId = d.materiaPrimaId > 0 ||
          (d.materiaPrimaCodigo != null && d.materiaPrimaCodigo!.trim().isNotEmpty);
      if (!hasValidId || d.cantidad <= 0) return false;
    }
    return true;
  }

  RecetasState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<Receta>? recetas,
    List<Insumo>? availableInsumos,
    List<Product>? availableProductos,
    List<Categoria>? availableCategorias,
    bool? usarProductoNuevo,
    bool? productoEditadoActivo,
    String? nuevoProductoNombre,
    String? nuevoProductoCodigo,
    int? nuevoProductoCategoriaId,
    bool quitarNuevoProductoCategoria = false,
    double? nuevoProductoPorcentaje,
    bool? nuevoProductoPreparacionBase,
    int? editingRecetaId,
    bool clearEditingId = false,
    String? selectedProductoCodigo,
    String? selectedProductoNombre,
    String? nombre,
    String? descripcion,
    double? costosAdicionales,
    List<RecetaDetalle>? detalles,
    double? costoTotal,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RecetasState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      recetas: recetas ?? this.recetas,
      availableInsumos: availableInsumos ?? this.availableInsumos,
      availableProductos: availableProductos ?? this.availableProductos,
      availableCategorias: availableCategorias ?? this.availableCategorias,
      usarProductoNuevo: usarProductoNuevo ?? this.usarProductoNuevo,
      productoEditadoActivo: productoEditadoActivo ?? this.productoEditadoActivo,
      nuevoProductoNombre: nuevoProductoNombre ?? this.nuevoProductoNombre,
      nuevoProductoCodigo: nuevoProductoCodigo ?? this.nuevoProductoCodigo,
      nuevoProductoCategoriaId: quitarNuevoProductoCategoria
          ? null
          : (nuevoProductoCategoriaId ?? this.nuevoProductoCategoriaId),
      nuevoProductoPorcentaje: nuevoProductoPorcentaje ?? this.nuevoProductoPorcentaje,
      nuevoProductoPreparacionBase:
          nuevoProductoPreparacionBase ?? this.nuevoProductoPreparacionBase,
      editingRecetaId: clearEditingId ? null : (editingRecetaId ?? this.editingRecetaId),
      selectedProductoCodigo: selectedProductoCodigo ?? this.selectedProductoCodigo,
      selectedProductoNombre: selectedProductoNombre ?? this.selectedProductoNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      costosAdicionales: costosAdicionales ?? this.costosAdicionales,
      detalles: detalles ?? this.detalles,
      costoTotal: costoTotal ?? this.costoTotal,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        errorMessage,
        successMessage,
        recetas,
        availableInsumos,
        availableProductos,
        availableCategorias,
        usarProductoNuevo,
        productoEditadoActivo,
        nuevoProductoNombre,
        nuevoProductoCodigo,
        nuevoProductoCategoriaId,
        nuevoProductoPorcentaje,
        nuevoProductoPreparacionBase,
        editingRecetaId,
        selectedProductoCodigo,
        selectedProductoNombre,
        nombre,
        descripcion,
        costosAdicionales,
        detalles,
        costoTotal,
      ];
}
