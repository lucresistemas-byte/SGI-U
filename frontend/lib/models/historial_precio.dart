import '../utils/parsers.dart';

/// Un cambio de costo o precio de un artículo (pestaña Historial de precios).
class HistorialPrecio {
  final int id;
  final DateTime fecha;
  final String codigo;
  final String nombre;
  final String tipo;
  final double? costoAnterior;
  final double? costoNuevo;
  final double? precioAnterior;
  final double? precioNuevo;
  final String modoPrecio;
  final String causa;
  final String? usuario;

  const HistorialPrecio({
    required this.id,
    required this.fecha,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.costoAnterior,
    this.costoNuevo,
    this.precioAnterior,
    this.precioNuevo,
    this.modoPrecio = 'MARGEN',
    required this.causa,
    this.usuario,
  });

  static double? _d(dynamic v) => v == null ? null : parseDouble(v);

  factory HistorialPrecio.fromJson(Map<String, dynamic> json) => HistorialPrecio(
        id: parseInt(json['id']),
        fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
        codigo: json['codigo']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? '',
        costoAnterior: _d(json['costoAnterior']),
        costoNuevo: _d(json['costoNuevo']),
        precioAnterior: _d(json['precioAnterior']),
        precioNuevo: _d(json['precioNuevo']),
        modoPrecio: json['modoPrecio']?.toString() ?? 'MARGEN',
        causa: json['causa']?.toString() ?? '',
        usuario: json['usuario']?.toString(),
      );

  /// Cambió el precio de venta (no solo el costo).
  bool get cambioPrecio => (precioAnterior ?? 0) != (precioNuevo ?? 0);
}
