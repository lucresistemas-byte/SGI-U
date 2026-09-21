import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/insumo.dart';
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
  }

  Future<void> _onCargarInsumos(
      CargarInsumos event, Emitter<InsumosState> emit) async {
    emit(InsumosLoading());
    try {
      final insumos = await _apiService.getInsumos();
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
        motivo: event.motivo,
      );
      emit(const InsumoOperacionExitosa('Stock ajustado correctamente'));
      add(const CargarInsumos());
    } catch (e) {
      emit(InsumosError(e.toString()));
    }
  }
}
