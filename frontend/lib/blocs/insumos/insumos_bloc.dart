import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'insumos_event.dart';
import 'insumos_state.dart';

class InsumosBloc extends Bloc<InsumosEvent, InsumosState> {
  final ApiService _apiService;

  InsumosBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(InsumosInitial()) {
    on<CargarInsumos>(_onCargarInsumos);
    on<FiltrarInsumos>(_onFiltrarInsumos);
    on<CrearInsumoEvent>(_onCrearInsumo);
    on<ActualizarInsumoEvent>(_onActualizarInsumo);
    on<AjustarStockInsumoEvent>(_onAjustarStockInsumo);
    on<CambiarEstadoInsumoEvent>(_onCambiarEstadoInsumo);
  }

  /// Nombres de las recetas activas que usan el insumo, para avisar antes de
  /// desactivarlo.
  Future<List<String>> recetasActivasQueUsan(int insumoId) async {
    final recetas = await _apiService.getRecetas();
    return recetas
        .where((r) => r.detalles.any((d) => d.articuloId == insumoId))
        .map((r) => r.nombre)
        .toList();
  }

  Future<void> _onCargarInsumos(
      CargarInsumos event, Emitter<InsumosState> emit) async {
    emit(InsumosLoading());
    try {
      // Se listan también los desactivados, para poder reactivarlos.
      final insumos = await _apiService.getInsumos(incluirInactivos: true);
      emit(InsumosLoaded(insumos: insumos));
    } catch (e) {
      emit(InsumosError(e.toString()));
    }
  }

  void _onFiltrarInsumos(FiltrarInsumos event, Emitter<InsumosState> emit) {
    if (state is InsumosLoaded) {
      final currentState = state as InsumosLoaded;
      final q = event.query.trim().toLowerCase();
      if (q.isEmpty) {
        emit(currentState.copyWith(
          filteredInsumos: currentState.insumos,
          searchQuery: '',
        ));
      } else {
        final filtered = currentState.insumos.where((i) {
          return i.nombre.toLowerCase().contains(q) ||
              i.codigo.toLowerCase().contains(q);
        }).toList();
        emit(currentState.copyWith(
          filteredInsumos: filtered,
          searchQuery: event.query,
        ));
      }
    }
  }

  Future<void> _onCrearInsumo(
      CrearInsumoEvent event, Emitter<InsumosState> emit) async {
    emit(InsumosLoading());
    try {
      await _apiService.createInsumo(event.data);
      emit(const InsumoOperacionExitosa('Insumo creado correctamente'));
      add(const CargarInsumos());
    } catch (e) {
      emit(InsumosError(e.toString()));
    }
  }

  Future<void> _onActualizarInsumo(
      ActualizarInsumoEvent event, Emitter<InsumosState> emit) async {
    emit(InsumosLoading());
    try {
      await _apiService.updateInsumo(event.id, event.data);
      emit(const InsumoOperacionExitosa('Insumo actualizado correctamente'));
      add(const CargarInsumos());
    } catch (e) {
      emit(InsumosError(e.toString()));
    }
  }

  Future<void> _onAjustarStockInsumo(
      AjustarStockInsumoEvent event, Emitter<InsumosState> emit) async {
    emit(InsumosLoading());
    try {
      await _apiService.ajustarStockInsumo(
        event.id,
        cantidad: event.cantidad,
        unidad: event.unidad,
        motivo: event.motivo,
        tipo: event.tipo,
      );
      emit(const InsumoOperacionExitosa('Stock ajustado correctamente'));
      add(const CargarInsumos());
    } catch (e) {
      emit(InsumosError(e.toString()));
    }
  }

  Future<void> _onCambiarEstadoInsumo(
      CambiarEstadoInsumoEvent event, Emitter<InsumosState> emit) async {
    emit(InsumosLoading());
    try {
      await _apiService.cambiarEstadoInsumo(event.id, activo: event.activo);
      emit(InsumoOperacionExitosa(
          event.activo ? 'Insumo reactivado' : 'Insumo desactivado'));
      add(const CargarInsumos());
    } catch (e) {
      emit(InsumosError(e.toString()));
    }
  }
}
