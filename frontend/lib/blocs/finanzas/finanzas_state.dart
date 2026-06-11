// lib/blocs/finanzas/finanzas_state.dart
import 'package:equatable/equatable.dart';

abstract class FinanzasState extends Equatable {
  const FinanzasState();
  @override
  List<Object?> get props => [];
}

class FinanzasInitial extends FinanzasState {}

class ResumenLoading extends FinanzasState {}

class ResumenLoaded extends FinanzasState {
  final Map<String, dynamic> resumen;
  const ResumenLoaded(this.resumen);
  @override
  List<Object?> get props => [resumen];
}

class MovimientosLoading extends FinanzasState {}

class MovimientosLoaded extends FinanzasState {
  final List<Map<String, dynamic>> movimientos;
  final int pagina;
  final int totalPaginas;
  const MovimientosLoaded(this.movimientos,
      {this.pagina = 1, this.totalPaginas = 1});
  @override
  List<Object?> get props => [movimientos, pagina, totalPaginas];
}

class MovimientosError extends FinanzasState {
  final String message;
  const MovimientosError(this.message);
  @override
  List<Object?> get props => [message];
}

class OperacionExitosa extends FinanzasState {
  final String mensaje;
  const OperacionExitosa(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

class BalanceLoading extends FinanzasState {}
class BalanceLoaded extends FinanzasState {
  final Map<String, dynamic> balance;
  const BalanceLoaded(this.balance);
  @override
  List<Object?> get props => [balance];
}