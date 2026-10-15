import '../utils/parsers.dart';

/// Tipos de movimiento de stock y su nombre para mostrar.
const tiposMovimientoStock = {
  'COMPRA': 'Compra',
  'AJUSTE': 'Ajuste',
  'MERMA': 'Merma',
  'PRODUCCION': 'Producción',
  'CONSUMO_PRODUCCION': 'Consumo de producción',
  'VENTA': 'Venta',
};

/// Una fila del historial de stock de un artículo.
class MovimientoStock {
  final int id;
  final DateTime fecha;
  final String tipo;
  final String tipoDescripcion;

  /// En unidad base, con signo.
  final double cantidad;
  final String cantidadTexto;
  final double stockResultante;
  final String stockResultanteTexto;
  final String? motivo;
  final int? produccionId;
  final int? ventaId;
  final String? usuario;

  const MovimientoStock({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.tipoDescripcion,
    required this.cantidad,
    required this.cantidadTexto,
    required this.stockResultante,
    required this.stockResultanteTexto,
    this.motivo,
    this.produccionId,
    this.ventaId,
    this.usuario,
  });

  factory MovimientoStock.fromJson(Map<String, dynamic> json) => MovimientoStock(
        id: parseInt(json['id']),
        fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
        tipo: json['tipo']?.toString() ?? '',
        tipoDescripcion: json['tipoDescripcion']?.toString() ?? tiposMovimientoStock[json['tipo']] ?? '',
        cantidad: parseDouble(json['cantidad']),
        cantidadTexto: json['cantidadTexto']?.toString() ?? '',
        stockResultante: parseDouble(json['stockResultante']),
        stockResultanteTexto: json['stockResultanteTexto']?.toString() ?? '',
        motivo: json['motivo']?.toString(),
        produccionId: json['produccionId'] != null ? parseInt(json['produccionId']) : null,
        ventaId: json['ventaId'] != null ? parseInt(json['ventaId']) : null,
        usuario: json['usuario']?.toString(),
      );
}

/// Un componente que no alcanza para producir.
class Faltante {
  final String codigo;
  final String nombre;
  final String mensaje;

  const Faltante({required this.codigo, required this.nombre, required this.mensaje});

  factory Faltante.fromJson(Map<String, dynamic> json) => Faltante(
        codigo: json['codigo']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        mensaje: json['mensaje']?.toString() ?? '',
      );

  /// Los faltantes que trae un 409 FALTAN_COMPONENTES.
  static List<Faltante> deDatos(Map<String, dynamic>? datos) {
    final lista = datos?['faltantes'];
    if (lista is! List) return const [];
    return lista.map((f) => Faltante.fromJson(Map<String, dynamic>.from(f as Map))).toList();
  }
}

/// Lo que consumió una producción.
class ConsumoProduccion {
  final String codigo;
  final String nombre;
  final String cantidadTexto;
  final String stockResultanteTexto;
  final bool negativo;

  const ConsumoProduccion({
    required this.codigo,
    required this.nombre,
    required this.cantidadTexto,
    required this.stockResultanteTexto,
    this.negativo = false,
  });

  factory ConsumoProduccion.fromJson(Map<String, dynamic> json) => ConsumoProduccion(
        codigo: json['codigo']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        cantidadTexto: json['cantidadTexto']?.toString() ?? '',
        stockResultanteTexto: json['stockResultanteTexto']?.toString() ?? '',
        negativo: json['negativo'] == true,
      );
}

/// Resultado de producir: stock nuevo del producto y lo consumido.
class ResultadoProduccion {
  final String codigo;
  final String nombre;
  final double cantidad;
  final bool conFaltantes;
  final int stockActual;
  final List<ConsumoProduccion> consumos;

  const ResultadoProduccion({
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    this.conFaltantes = false,
    this.stockActual = 0,
    this.consumos = const [],
  });

  factory ResultadoProduccion.fromJson(Map<String, dynamic> json) => ResultadoProduccion(
        codigo: json['codigo']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        cantidad: parseDouble(json['cantidad']),
        conFaltantes: json['conFaltantes'] == true,
        stockActual: parseInt(json['stockActual']),
        consumos: json['consumos'] is List
            ? (json['consumos'] as List)
                .map((c) => ConsumoProduccion.fromJson(Map<String, dynamic>.from(c as Map)))
                .toList()
            : const [],
      );
}
