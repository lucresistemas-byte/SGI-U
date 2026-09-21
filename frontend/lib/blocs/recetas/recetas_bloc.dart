import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../models/receta_detalle.dart';
import '../../services/api_service.dart';
import 'recetas_event.dart';
import 'recetas_state.dart';

class RecetasBloc extends Bloc<RecetasEvent, RecetasState> {
  final ApiService _apiService;

  RecetasBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(RecetasState.initial()) {
    on<CargarRecetas>(_onCargarRecetas);
    on<CargarDatosAuxiliaresReceta>(_onCargarDatosAuxiliaresReceta);
    on<IniciarNuevaReceta>(_onIniciarNuevaReceta);
    on<EditarReceta>(_onEditarReceta);
    on<CambiarProductoReceta>(_onCambiarProductoReceta);
    on<CambiarNombreReceta>(_onCambiarNombreReceta);
    on<CambiarDescripcionReceta>(_onCambiarDescripcionReceta);
    on<CambiarCostosAdicionales>(_onCambiarCostosAdicionales);
    on<AgregarFilaInsumo>(_onAgregarFilaInsumo);
    on<RemoverFilaInsumo>(_onRemoverFilaInsumo);
    on<ActualizarCantidadFilaInsumo>(_onActualizarCantidadFilaInsumo);
    on<GuardarReceta>(_onGuardarReceta);
    on<EliminarReceta>(_onEliminarReceta);
  }

  double _calcularCostoTotal(List<RecetaDetalle> detalles, double adicionales) {
    final sum = detalles.fold<double>(0.0, (acc, item) => acc + item.subtotal);
    return sum + adicionales;
  }

  Future<void> _onCargarRecetas(
      CargarRecetas event, Emitter<RecetasState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final recetas = await _apiService.getRecetas();
      emit(state.copyWith(isLoading: false, recetas: recetas));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCargarDatosAuxiliaresReceta(
      CargarDatosAuxiliaresReceta event, Emitter<RecetasState> emit) async {
    try {
      final insumos = await _apiService.getInsumos();
      final rawProducts = await _apiService.getProducts();
      final products = rawProducts
          .map((p) => Product.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      emit(state.copyWith(
        availableInsumos: insumos,
        availableProductos: products,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onIniciarNuevaReceta(
      IniciarNuevaReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(
      clearEditingId: true,
      selectedProductoCodigo: event.defaultProductoCodigo ?? '',
      selectedProductoNombre: event.defaultProductoNombre ?? '',
      nombre: '',
      descripcion: '',
      costosAdicionales: 0.0,
      detalles: const [],
      costoTotal: 0.0,
      clearError: true,
      clearSuccess: true,
    ));
  }

  void _onEditarReceta(EditarReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(
      editingRecetaId: event.receta.id,
      selectedProductoCodigo: event.receta.espProductoCodigo,
      selectedProductoNombre: event.receta.espProductoNombre ?? '',
      nombre: event.receta.nombre,
      descripcion: event.receta.descripcion ?? '',
      costosAdicionales: event.receta.costosAdicionales,
      detalles: List<RecetaDetalle>.from(event.receta.detalles),
      costoTotal: event.receta.costoTotal,
      clearError: true,
      clearSuccess: true,
    ));
  }

  void _onCambiarProductoReceta(
      CambiarProductoReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(
      selectedProductoCodigo: event.codigo,
      selectedProductoNombre: event.nombre,
    ));
  }

  void _onCambiarNombreReceta(
      CambiarNombreReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(nombre: event.nombre));
  }

  void _onCambiarDescripcionReceta(
      CambiarDescripcionReceta event, Emitter<RecetasState> emit) {
    emit(state.copyWith(descripcion: event.descripcion));
  }

  void _onCambiarCostosAdicionales(
      CambiarCostosAdicionales event, Emitter<RecetasState> emit) {
    final total = _calcularCostoTotal(state.detalles, event.costosAdicionales);
    emit(state.copyWith(
      costosAdicionales: event.costosAdicionales,
      costoTotal: total,
    ));
  }

  void _onAgregarFilaInsumo(
      AgregarFilaInsumo event, Emitter<RecetasState> emit) {
    final nuevoDetalle = RecetaDetalle(
      materiaPrimaId: event.insumo.id ?? 0,
      materiaPrimaCodigo: event.insumo.codigo,
      materiaPrimaNombre: event.insumo.nombre,
      cantidad: event.cantidad,
      unidadMedida: event.insumo.unidadMedida,
      costoUnitario: event.insumo.costoUnitario,
      subtotal: event.cantidad * event.insumo.costoUnitario,
    );

    final nuevosDetalles = List<RecetaDetalle>.from(state.detalles)..add(nuevoDetalle);
    final total = _calcularCostoTotal(nuevosDetalles, state.costosAdicionales);

    emit(state.copyWith(
      detalles: nuevosDetalles,
      costoTotal: total,
    ));
  }

  void _onRemoverFilaInsumo(
      RemoverFilaInsumo event, Emitter<RecetasState> emit) {
    if (event.index >= 0 && event.index < state.detalles.length) {
      final nuevosDetalles = List<RecetaDetalle>.from(state.detalles)..removeAt(event.index);
      final total = _calcularCostoTotal(nuevosDetalles, state.costosAdicionales);

      emit(state.copyWith(
        detalles: nuevosDetalles,
        costoTotal: total,
      ));
    }
  }

  void _onActualizarCantidadFilaInsumo(
      ActualizarCantidadFilaInsumo event, Emitter<RecetasState> emit) {
    if (event.index >= 0 && event.index < state.detalles.length) {
      final item = state.detalles[event.index];
      final updatedItem = item.copyWith(
        cantidad: event.cantidad,
        subtotal: event.cantidad * item.costoUnitario,
      );
      final nuevosDetalles = List<RecetaDetalle>.from(state.detalles);
      nuevosDetalles[event.index] = updatedItem;
      final total = _calcularCostoTotal(nuevosDetalles, state.costosAdicionales);

      emit(state.copyWith(
        detalles: nuevosDetalles,
        costoTotal: total,
      ));
    }
  }

  Future<void> _onGuardarReceta(
      GuardarReceta event, Emitter<RecetasState> emit) async {
    if (!state.isFormValid) {
      emit(state.copyWith(
        errorMessage: 'Por favor complete todos los campos requeridos de la receta.',
      ));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final payload = {
        'espProductoCodigo': state.selectedProductoCodigo,
        'nombre': state.nombre,
        if (state.descripcion.isNotEmpty) 'descripcion': state.descripcion,
        'costosAdicionales': state.costosAdicionales,
        'detalles': state.detalles.map((d) => {
          'materiaPrimaId': d.materiaPrimaId,
          'cantidad': d.cantidad,
          'unidadMedida': d.unidadMedida,
        }).toList(),
      };

      if (state.editingRecetaId == null) {
        await _apiService.createReceta(payload);
        emit(state.copyWith(
          isSaving: false,
          successMessage: 'Receta creada exitosamente',
        ));
      } else {
        await _apiService.updateReceta(state.editingRecetaId!, payload);
        emit(state.copyWith(
          isSaving: false,
          successMessage: 'Receta actualizada exitosamente',
        ));
      }
      add(const CargarRecetas());
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onEliminarReceta(
      EliminarReceta event, Emitter<RecetasState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _apiService.deleteReceta(event.id);
      emit(state.copyWith(
        isLoading: false,
        successMessage: 'Receta eliminada exitosamente',
      ));
      add(const CargarRecetas());
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
