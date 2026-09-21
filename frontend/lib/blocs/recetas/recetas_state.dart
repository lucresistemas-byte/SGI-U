import 'package:equatable/equatable.dart';
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

  bool get isFormValid {
    if (selectedProductoCodigo.trim().isEmpty) return false;
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
