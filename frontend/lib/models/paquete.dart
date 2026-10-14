import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';

/// Una fila del armado de un paquete: un insumo con su cantidad.
class FilaArmado extends Equatable {
  final int articuloId;
  final String? articuloCodigo;
  final String? articuloNombre;
  final double cantidad;
  final String unidadMedida;

  /// Costo por la unidad elegida y subtotal (los manda el backend).
  final double costoUnitario;
  final double subtotal;

  const FilaArmado({
    required this.articuloId,
    this.articuloCodigo,
    this.articuloNombre,
    required this.cantidad,
    this.unidadMedida = 'UNIDAD',
    this.costoUnitario = 0,
    this.subtotal = 0,
  });

  factory FilaArmado.fromJson(Map<String, dynamic> json) => FilaArmado(
        articuloId: parseInt(json['articuloId']),
        articuloCodigo: json['articuloCodigo']?.toString(),
        articuloNombre: json['articuloNombre']?.toString(),
        cantidad: parseDouble(json['cantidad']),
        unidadMedida: json['unidadMedida']?.toString() ?? 'UNIDAD',
        costoUnitario: parseDouble(json['costoUnitario']),
        subtotal: parseDouble(json['subtotal']),
      );

  Map<String, dynamic> toJson() => {'articuloId': articuloId, 'cantidad': cantidad, 'unidadMedida': unidadMedida};

  @override
  List<Object?> get props => [articuloId, cantidad, unidadMedida];
}

/// Paquete (PAQ-0001): armado de insumos + monto fijo. Precio = costo del
/// armado + monto fijo, redondeado hacia arriba a $100.
class Paquete extends Equatable {
  final int id;
  final String codigo;
  final String nombre;
  final int? categoriaId;
  final String? categoria;
  final bool activo;
  final double costoArmado;
  final double montoFijo;
  final double precioVenta;
  final double gananciaPesos;
  final int stockActual;
  final List<FilaArmado> armado;

  const Paquete({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.categoriaId,
    this.categoria,
    this.activo = true,
    this.costoArmado = 0,
    this.montoFijo = 0,
    this.precioVenta = 0,
    this.gananciaPesos = 0,
    this.stockActual = 0,
    this.armado = const [],
  });

  factory Paquete.fromJson(Map<String, dynamic> json) => Paquete(
        id: parseInt(json['id']),
        codigo: json['codigo']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        categoriaId: json['categoriaId'] != null ? parseInt(json['categoriaId']) : null,
        categoria: json['categoria']?.toString(),
        activo: json['activo'] != false,
        costoArmado: parseDouble(json['costoArmado']),
        montoFijo: parseDouble(json['montoFijo']),
        precioVenta: parseDouble(json['precioVenta']),
        gananciaPesos: parseDouble(json['gananciaPesos']),
        stockActual: parseInt(json['stockActual']),
        armado: json['armado'] is List
            ? (json['armado'] as List).map((f) => FilaArmado.fromJson(Map<String, dynamic>.from(f as Map))).toList()
            : const [],
      );

  @override
  List<Object?> get props =>
      [id, codigo, nombre, categoriaId, activo, costoArmado, montoFijo, precioVenta, gananciaPesos, armado];
}
