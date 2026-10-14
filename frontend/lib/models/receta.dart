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

  /// false = el producto elaborado está desactivado (no se vende en el POS).
  /// La receta sigue visible.
  final bool productoActivo;

  /// Cuánto rinde (p. ej. 8) y qué ("porciones").
  final double rinde;
  final String rindeUnidad;

  /// Costo por unidad rendida = costoTotal / rinde.
  final double costoPorUnidad;
  final double porcentajeGanancia;
  final double precioVenta;

  /// Precio − costo por unidad (null en preparaciones base).
  final double? gananciaPorUnidad;
  final String modoPrecio;

  /// Preparación base: rinde en peso o volumen ([rindeUnidadMedida]) y no se vende.
  final bool preparacionBase;
  final String? rindeUnidadMedida;

  /// Preparación base: costo por unidad base del rinde (por gramo, por ml).
  final double? costoUnidadBase;

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
    this.productoActivo = true,
    this.rinde = 1,
    this.rindeUnidad = 'unidades',
    this.costoPorUnidad = 0,
    this.porcentajeGanancia = 0,
    this.precioVenta = 0,
    this.gananciaPorUnidad,
    this.modoPrecio = 'MARGEN',
    this.preparacionBase = false,
    this.rindeUnidadMedida,
    this.costoUnidadBase,
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
      productoActivo: json['productoActivo'] != false,
      rinde: json['rinde'] != null ? parseDouble(json['rinde']) : 1,
      rindeUnidad: json['rindeUnidad']?.toString() ?? 'unidades',
      costoPorUnidad: parseDouble(json['costoPorUnidad']),
      porcentajeGanancia: parseDouble(json['porcentajeGanancia']),
      precioVenta: parseDouble(json['precioVenta']),
      gananciaPorUnidad: json['gananciaPorUnidad'] != null ? parseDouble(json['gananciaPorUnidad']) : null,
      modoPrecio: json['modoPrecio']?.toString() ?? 'MARGEN',
      preparacionBase: json['preparacionBase'] == true,
      rindeUnidadMedida: json['rindeUnidadMedida']?.toString(),
      costoUnidadBase: json['costoUnidadBase'] != null ? parseDouble(json['costoUnidadBase']) : null,
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
        'articuloId': d.articuloId,
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
    bool? productoActivo,
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
      productoActivo: productoActivo ?? this.productoActivo,
      rinde: rinde,
      rindeUnidad: rindeUnidad,
      costoPorUnidad: costoPorUnidad,
      porcentajeGanancia: porcentajeGanancia,
      precioVenta: precioVenta,
      gananciaPorUnidad: gananciaPorUnidad,
      modoPrecio: modoPrecio,
      preparacionBase: preparacionBase,
      rindeUnidadMedida: rindeUnidadMedida,
      costoUnidadBase: costoUnidadBase,
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
        rinde,
        rindeUnidad,
      ];
}
