import '../utils/parsers.dart';

/// Un precio de venta que cambió por una propagación (resumen "Se actualizaron N precios").
class CambioPrecio {
  final String codigo;
  final String nombre;
  final double precioAnterior;
  final double precioNuevo;
  final double costoNuevo;
  final double gananciaPesos;

  const CambioPrecio({
    required this.codigo,
    required this.nombre,
    required this.precioAnterior,
    required this.precioNuevo,
    this.costoNuevo = 0,
    this.gananciaPesos = 0,
  });

  factory CambioPrecio.fromJson(Map<String, dynamic> json) => CambioPrecio(
        codigo: json['codigo']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        precioAnterior: parseDouble(json['precioAnterior']),
        precioNuevo: parseDouble(json['precioNuevo']),
        costoNuevo: parseDouble(json['costoNuevo']),
        gananciaPesos: parseDouble(json['gananciaPesos']),
      );

  /// Los cambios que trae la respuesta de un guardado (campo cambiosDePrecio).
  static List<CambioPrecio> deRespuesta(dynamic data) {
    if (data is! Map || data['cambiosDePrecio'] is! List) return const [];
    return (data['cambiosDePrecio'] as List)
        .map((c) => CambioPrecio.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }
}
