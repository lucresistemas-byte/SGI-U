import 'package:equatable/equatable.dart';
import '../../models/pedido.dart';

class PedidosState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final List<Pedido> pedidos;
  final List<Pedido> filteredPedidos;
  final Pedido? selectedPedido;
  final String searchQuery;

  const PedidosState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.pedidos = const [],
    this.filteredPedidos = const [],
    this.selectedPedido,
    this.searchQuery = '',
  });

  factory PedidosState.initial() => const PedidosState();

  PedidosState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    List<Pedido>? pedidos,
    List<Pedido>? filteredPedidos,
    Pedido? selectedPedido,
    bool clearSelectedPedido = false,
    String? searchQuery,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PedidosState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      pedidos: pedidos ?? this.pedidos,
      filteredPedidos: filteredPedidos ?? this.filteredPedidos,
      selectedPedido: clearSelectedPedido ? null : (selectedPedido ?? this.selectedPedido),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
        pedidos,
        filteredPedidos,
        selectedPedido,
        searchQuery,
      ];
}
