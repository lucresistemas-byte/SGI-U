import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';

class RecetaDetalle extends Equatable {
  final int? id;
  final int articuloId;
  final String? articuloCodigo;
  final String? articuloNombre;
  final double cantidad;
  final String unidadMedida;
  final double costoUnitario;
  final double subtotal;

  /// Clave estable de la fila en el armador (solo UI, no se envía ni se
  /// compara): identifica la fila aunque cambie su insumo o esté vacía.
  final int? claveUi;

  /// Fila recién agregada, todavía sin insumo elegido.
  bool get sinInsumo => articuloId <= 0;

  /// Fila con insumo y cantidad: se puede guardar.
  bool get completa => !sinInsumo && cantidad > 0;

  const RecetaDetalle({
    this.id,
    required this.articuloId,
    this.articuloCodigo,
    this.articuloNombre,
    required this.cantidad,
    this.unidadMedida = 'UNIDAD',
    this.costoUnitario = 0.0,
    double? subtotal,
    this.claveUi,
  }) : subtotal = subtotal ?? (cantidad * costoUnitario);

  factory RecetaDetalle.fromJson(Map<String, dynamic> json) {
    final cantidad = parseDouble(json['cantidad']);
    final costoUnitario = parseDouble(json['costoUnitario'] ?? json['costo_unitario']);
    final subtotal = json['subtotal'] != null
        ? parseDouble(json['subtotal'])
        : (cantidad * costoUnitario);

    return RecetaDetalle(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      articuloId: parseInt(json['articuloId'] ?? json['articulo_id']),
      articuloCodigo: json['articuloCodigo']?.toString() ?? json['articulo_codigo']?.toString(),
      articuloNombre: json['articuloNombre']?.toString() ?? json['articulo_nombre']?.toString(),
      cantidad: cantidad,
      unidadMedida: json['unidadMedida']?.toString() ?? json['unidad_medida']?.toString() ?? 'UNIDAD',
      costoUnitario: costoUnitario,
      subtotal: subtotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'articuloId': articuloId,
      if (articuloCodigo != null) 'articuloCodigo': articuloCodigo,
      if (articuloNombre != null) 'articuloNombre': articuloNombre,
      'cantidad': cantidad,
      'unidadMedida': unidadMedida,
      'costoUnitario': costoUnitario,
      'subtotal': subtotal,
    };
  }

  RecetaDetalle copyWith({
    int? id,
    int? articuloId,
    String? articuloCodigo,
    String? articuloNombre,
    double? cantidad,
    String? unidadMedida,
    double? costoUnitario,
    double? subtotal,
    int? claveUi,
  }) {
    final cant = cantidad ?? this.cantidad;
    final costo = costoUnitario ?? this.costoUnitario;
    return RecetaDetalle(
      id: id ?? this.id,
      articuloId: articuloId ?? this.articuloId,
      articuloCodigo: articuloCodigo ?? this.articuloCodigo,
      articuloNombre: articuloNombre ?? this.articuloNombre,
      cantidad: cant,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      costoUnitario: costo,
      subtotal: subtotal ?? (cant * costo),
      claveUi: claveUi ?? this.claveUi,
    );
  }

  @override
  List<Object?> get props => [
        id,
        articuloId,
        articuloCodigo,
        articuloNombre,
        cantidad,
        unidadMedida,
        costoUnitario,
        subtotal,
      ];
}
