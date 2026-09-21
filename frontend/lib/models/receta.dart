import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';
import 'receta_detalle.dart';

class Receta extends Equatable {
  final int? id;
  final String espProductoCodigo;
  final String? espProductoNombre;
  final String nombre;
  final String? descripcion;
  final double costosAdicionales;
  final double costoTotal;
  final List<RecetaDetalle> detalles;
  final bool activo;

  const Receta({
    this.id,
    required this.espProductoCodigo,
    this.espProductoNombre,
    required this.nombre,
    this.descripcion,
    this.costosAdicionales = 0.0,
    double? costoTotal,
    this.detalles = const [],
    this.activo = true,
  }) : costoTotal = costoTotal ?? 0.0;

  factory Receta.fromJson(Map<String, dynamic> json) {
    List<RecetaDetalle> detallesList = [];
    if (json['detalles'] is List) {
      detallesList = (json['detalles'] as List)
          .map((d) => RecetaDetalle.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
    }

    final double adicionales = parseDouble(json['costosAdicionales'] ?? json['costos_adicionales']);
    double calculatedCosto = parseDouble(json['costoTotal'] ?? json['costo_total']);
    if (calculatedCosto == 0.0 && detallesList.isNotEmpty) {
      calculatedCosto = detallesList.fold(0.0, (acc, item) => acc + item.subtotal) + adicionales;
    }

    return Receta(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      espProductoCodigo: json['espProductoCodigo']?.toString() ?? json['esp_producto_codigo']?.toString() ?? '',
      espProductoNombre: json['espProductoNombre']?.toString() ?? json['esp_producto_nombre']?.toString(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      costosAdicionales: adicionales,
      costoTotal: calculatedCosto,
      detalles: detallesList,
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'espProductoCodigo': espProductoCodigo,
      if (espProductoNombre != null) 'espProductoNombre': espProductoNombre,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'costosAdicionales': costosAdicionales,
      'costoTotal': costoTotal,
      'detalles': detalles.map((d) => {
        'materiaPrimaId': d.materiaPrimaId,
        'cantidad': d.cantidad,
        'unidadMedida': d.unidadMedida,
      }).toList(),
      'activo': activo,
    };
  }

  Receta copyWith({
    int? id,
    String? espProductoCodigo,
    String? espProductoNombre,
    String? nombre,
    String? descripcion,
    double? costosAdicionales,
    double? costoTotal,
    List<RecetaDetalle>? detalles,
    bool? activo,
  }) {
    final list = detalles ?? this.detalles;
    final extra = costosAdicionales ?? this.costosAdicionales;
    final total = costoTotal ?? (list.fold(0.0, (acc, item) => acc + item.subtotal) + extra);

    return Receta(
      id: id ?? this.id,
      espProductoCodigo: espProductoCodigo ?? this.espProductoCodigo,
      espProductoNombre: espProductoNombre ?? this.espProductoNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      costosAdicionales: extra,
      costoTotal: total,
      detalles: list,
      activo: activo ?? this.activo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        espProductoCodigo,
        espProductoNombre,
        nombre,
        descripcion,
        costosAdicionales,
        costoTotal,
        detalles,
        activo,
      ];
}
