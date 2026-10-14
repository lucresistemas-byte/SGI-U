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

  /// Rinde de la receta (obligatorio, > 0) y qué rinde ("porciones").
  final double? rinde;
  final String rindeUnidad;

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
    this.rinde,
    this.rindeUnidad = 'porciones',
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

  /// Costo por unidad rendida (porción, alfajor...): costo total / rinde.
  double? get costoPorUnidad => rinde != null && rinde! > 0 ? costoTotal / rinde! : null;

  /// % de ganancia del producto: el del producto nuevo o el del existente.
  double get porcentajeGanancia {
    if (creaProductoNuevo) return nuevoProductoPorcentaje ?? 0;
    for (final p in availableProductos) {
      if (p.codigo == selectedProductoCodigo) return p.porcentajeGanancia ?? 0;
    }
    return 0;
  }

  /// Precio resultante = costo por unidad × (1 + % ganancia).
  double? get precioResultante {
    final c = costoPorUnidad;
    return c == null ? null : c * (1 + porcentajeGanancia / 100);
  }

  bool get creaProductoNuevo => editingRecetaId == null && usarProductoNuevo;

  bool get isFormValid {
    if (creaProductoNuevo) {
      if (nuevoProductoNombre.trim().isEmpty) return false;
      if (nuevoProductoCategoriaId == null) return false;
    } else if (selectedProductoCodigo.trim().isEmpty) {
      return false;
    }
    if (nombre.trim().isEmpty) return false;
    if (rinde == null || rinde! <= 0) return false;
    if (detalles.isEmpty) return false;
    for (final d in detalles) {
      final hasValidId = d.articuloId > 0 ||
          (d.articuloCodigo != null && d.articuloCodigo!.trim().isNotEmpty);
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
    double? rinde,
    bool quitarRinde = false,
    String? rindeUnidad,
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
      rinde: quitarRinde ? null : (rinde ?? this.rinde),
      rindeUnidad: rindeUnidad ?? this.rindeUnidad,
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
        rinde,
        rindeUnidad,
      ];
}
