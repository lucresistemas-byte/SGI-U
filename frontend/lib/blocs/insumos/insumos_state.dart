import 'package:equatable/equatable.dart';
import '../../models/insumo.dart';

abstract class InsumosState extends Equatable {
  const InsumosState();

  @override
  List<Object?> get props => [];
}

class InsumosInitial extends InsumosState {}

class InsumosLoading extends InsumosState {}

class InsumosLoaded extends InsumosState {
  final List<Insumo> insumos;
  final List<Insumo> filteredInsumos;
  final String searchQuery;

  InsumosLoaded({
    required this.insumos,
    List<Insumo>? filteredInsumos,
    this.searchQuery = '',
  }) : filteredInsumos = filteredInsumos ?? insumos;

  InsumosLoaded copyWith({
    List<Insumo>? insumos,
    List<Insumo>? filteredInsumos,
    String? searchQuery,
  }) {
    return InsumosLoaded(
      insumos: insumos ?? this.insumos,
      filteredInsumos: filteredInsumos ?? this.filteredInsumos,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [insumos, filteredInsumos, searchQuery];
}

class InsumosError extends InsumosState {
  final String message;
  const InsumosError(this.message);

  @override
  List<Object?> get props => [message];
}

class InsumoOperacionExitosa extends InsumosState {
  final String mensaje;
  const InsumoOperacionExitosa(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
