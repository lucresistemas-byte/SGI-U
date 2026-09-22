import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'pedidos_event.dart';
import 'pedidos_state.dart';

class PedidosBloc extends Bloc<PedidosEvent, PedidosState> {
  final ApiService _apiService;

  PedidosBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(PedidosState.initial()) {
    on<CargarPedidos>(_onCargarPedidos);
    on<BuscarPedidos>(_onBuscarPedidos);
    on<CrearPedidoEvent>(_onCrearPedido);
    on<RegistrarAbonoEvent>(_onRegistrarAbono);
    on<CancelarPedidoEvent>(_onCancelarPedido);
    on<SeleccionarPedido>(_onSeleccionarPedido);
    on<LimpiarMensajesPedidos>(_onLimpiarMensajes);
  }

  Future<void> _onCargarPedidos(
      CargarPedidos event, Emitter<PedidosState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final pedidos = await _apiService.getPedidos(query: event.query);
      emit(state.copyWith(
        isLoading: false,
        pedidos: pedidos,
        filteredPedidos: pedidos,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onBuscarPedidos(BuscarPedidos event, Emitter<PedidosState> emit) {
    final q = event.query.trim().toLowerCase();
    if (q.isEmpty) {
      emit(state.copyWith(
        filteredPedidos: state.pedidos,
        searchQuery: '',
      ));
    } else {
      final filtered = state.pedidos.where((p) {
        return p.clienteNombre.toLowerCase().contains(q) ||
            p.clienteTelefono.toLowerCase().contains(q) ||
            p.descripcion.toLowerCase().contains(q);
      }).toList();
      emit(state.copyWith(
        filteredPedidos: filtered,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onCrearPedido(
      CrearPedidoEvent event, Emitter<PedidosState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiService.createPedido(event.data);
      emit(state.copyWith(
        isSubmitting: false,
        successMessage: 'Pedido registrado con éxito',
      ));
      add(const CargarPedidos());
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRegistrarAbono(
      RegistrarAbonoEvent event, Emitter<PedidosState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final actualizado = await _apiService.abonarPedido(
        event.pedidoId,
        monto: event.monto,
        metodoPago: event.metodoPago,
        nota: event.nota,
      );

      final updatedList = state.pedidos
          .map((p) => p.id == actualizado.id ? actualizado : p)
          .toList();
      final updatedFiltered = state.filteredPedidos
          .map((p) => p.id == actualizado.id ? actualizado : p)
          .toList();
      final newSelected = state.selectedPedido?.id == actualizado.id
          ? actualizado
          : state.selectedPedido;

      emit(state.copyWith(
        isSubmitting: false,
        pedidos: updatedList,
        filteredPedidos: updatedFiltered,
        selectedPedido: newSelected,
        successMessage: 'Abono registrado correctamente',
      ));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCancelarPedido(
      CancelarPedidoEvent event, Emitter<PedidosState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiService.cancelarPedido(event.pedidoId);
      emit(state.copyWith(
        isSubmitting: false,
        successMessage: 'Pedido cancelado correctamente',
      ));
      add(const CargarPedidos());
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  void _onSeleccionarPedido(
      SeleccionarPedido event, Emitter<PedidosState> emit) {
    emit(state.copyWith(selectedPedido: event.pedido));
  }

  void _onLimpiarMensajes(
      LimpiarMensajesPedidos event, Emitter<PedidosState> emit) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
