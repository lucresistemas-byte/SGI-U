import '../utils/parsers.dart';

class Movimiento {
  final int? id;
  final String tipo; // 'INGRESO' o 'EGRESO'
  final double monto;
  final String metodoPago;
  final String categoria;
  final String descripcion;
  final DateTime? fechaHora;
  final double costo;
  final double ganancia;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    this.metodoPago = '',
    this.categoria = '',
    this.descripcion = '',
    this.fechaHora,
    this.costo = 0.0,
    this.ganancia = 0.0,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    DateTime? parsedFecha;
    if (json['fechaHora'] != null) {
      parsedFecha = DateTime.tryParse(json['fechaHora'].toString());
    } else if (json['fecha_hora'] != null) {
      parsedFecha = DateTime.tryParse(json['fecha_hora'].toString());
    }

    return Movimiento(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      tipo: json['tipo']?.toString() ?? '',
      monto: parseDouble(json['monto']),
      metodoPago: json['metodoPago']?.toString() ?? json['metodo_pago']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      fechaHora: parsedFecha,
      costo: parseDouble(json['costo']),
      ganancia: parseDouble(json['ganancia']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tipo': tipo,
      'monto': monto,
      'metodoPago': metodoPago,
      'categoria': categoria,
      'descripcion': descripcion,
      if (fechaHora != null) 'fechaHora': fechaHora!.toIso8601String(),
      'costo': costo,
      'ganancia': ganancia,
    };
  }

  Movimiento copyWith({
    int? id,
    String? tipo,
    double? monto,
    String? metodoPago,
    String? categoria,
    String? descripcion,
    DateTime? fechaHora,
    double? costo,
    double? ganancia,
  }) {
    return Movimiento(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      fechaHora: fechaHora ?? this.fechaHora,
      costo: costo ?? this.costo,
      ganancia: ganancia ?? this.ganancia,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movimiento &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tipo == other.tipo &&
          monto == other.monto &&
          metodoPago == other.metodoPago &&
          categoria == other.categoria &&
          descripcion == other.descripcion &&
          fechaHora == other.fechaHora &&
          costo == other.costo &&
          ganancia == other.ganancia;

  @override
  int get hashCode =>
      id.hashCode ^
      tipo.hashCode ^
      monto.hashCode ^
      metodoPago.hashCode ^
      categoria.hashCode ^
      descripcion.hashCode ^
      fechaHora.hashCode ^
      costo.hashCode ^
      ganancia.hashCode;
}
