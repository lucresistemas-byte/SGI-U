// lib/blocs/finanzas/finanzas_event.dart
import 'package:equatable/equatable.dart';

abstract class FinanzasEvent extends Equatable {
  const FinanzasEvent();
  @override
  List<Object?> get props => [];
}

class CargarResumen extends FinanzasEvent {}

class CargarMovimientos extends FinanzasEvent {
  final int pagina;
  final int? limite;
  const CargarMovimientos({this.pagina = 1, this.limite = 10});
  @override
  List<Object?> get props => [pagina, limite];
}

class CrearMovimiento extends FinanzasEvent {
  final String tipo;
  final double monto;
  final String metodoPago;
  final String categoria;
  final String descripcion;
  const CrearMovimiento({
    required this.tipo,
    required this.monto,
    required this.metodoPago,
    required this.categoria,
    required this.descripcion,
  });
  @override
  List<Object?> get props => [tipo, monto, metodoPago, categoria, descripcion];
}

class CargarBalance extends FinanzasEvent {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  const CargarBalance(this.fechaInicio, this.fechaFin);
  @override
  List<Object?> get props => [fechaInicio, fechaFin];
}
