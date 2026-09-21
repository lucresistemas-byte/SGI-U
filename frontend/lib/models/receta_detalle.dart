import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';

class RecetaDetalle extends Equatable {
  final int? id;
  final int materiaPrimaId;
  final String? materiaPrimaCodigo;
  final String? materiaPrimaNombre;
  final double cantidad;
  final String unidadMedida;
  final double costoUnitario;
  final double subtotal;

  const RecetaDetalle({
    this.id,
    required this.materiaPrimaId,
    this.materiaPrimaCodigo,
    this.materiaPrimaNombre,
    required this.cantidad,
    this.unidadMedida = 'UNIDAD',
    this.costoUnitario = 0.0,
    double? subtotal,
  }) : subtotal = subtotal ?? (cantidad * costoUnitario);

  factory RecetaDetalle.fromJson(Map<String, dynamic> json) {
    final cantidad = parseDouble(json['cantidad']);
    final costoUnitario = parseDouble(json['costoUnitario'] ?? json['costo_unitario']);
    final subtotal = json['subtotal'] != null
        ? parseDouble(json['subtotal'])
        : (cantidad * costoUnitario);

    return RecetaDetalle(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      materiaPrimaId: parseInt(json['materiaPrimaId'] ?? json['materia_prima_id']),
      materiaPrimaCodigo: json['materiaPrimaCodigo']?.toString() ?? json['materia_prima_codigo']?.toString(),
      materiaPrimaNombre: json['materiaPrimaNombre']?.toString() ?? json['materia_prima_nombre']?.toString(),
      cantidad: cantidad,
      unidadMedida: json['unidadMedida']?.toString() ?? json['unidad_medida']?.toString() ?? 'UNIDAD',
      costoUnitario: costoUnitario,
      subtotal: subtotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'materiaPrimaId': materiaPrimaId,
      if (materiaPrimaCodigo != null) 'materiaPrimaCodigo': materiaPrimaCodigo,
      if (materiaPrimaNombre != null) 'materiaPrimaNombre': materiaPrimaNombre,
      'cantidad': cantidad,
      'unidadMedida': unidadMedida,
      'costoUnitario': costoUnitario,
      'subtotal': subtotal,
    };
  }

  RecetaDetalle copyWith({
    int? id,
    int? materiaPrimaId,
    String? materiaPrimaCodigo,
    String? materiaPrimaNombre,
    double? cantidad,
    String? unidadMedida,
    double? costoUnitario,
    double? subtotal,
  }) {
    final cant = cantidad ?? this.cantidad;
    final costo = costoUnitario ?? this.costoUnitario;
    return RecetaDetalle(
      id: id ?? this.id,
      materiaPrimaId: materiaPrimaId ?? this.materiaPrimaId,
      materiaPrimaCodigo: materiaPrimaCodigo ?? this.materiaPrimaCodigo,
      materiaPrimaNombre: materiaPrimaNombre ?? this.materiaPrimaNombre,
      cantidad: cant,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      costoUnitario: costo,
      subtotal: subtotal ?? (cant * costo),
    );
  }

  @override
  List<Object?> get props => [
        id,
        materiaPrimaId,
        materiaPrimaCodigo,
        materiaPrimaNombre,
        cantidad,
        unidadMedida,
        costoUnitario,
        subtotal,
      ];
}
