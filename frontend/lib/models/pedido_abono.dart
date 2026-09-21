import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';

class PedidoAbono extends Equatable {
  final int? id;
  final double monto;
  final String metodoPago;
  final String? nota;
  final DateTime? fecha;

  const PedidoAbono({
    this.id,
    required this.monto,
    this.metodoPago = 'EFECTIVO',
    this.nota,
    this.fecha,
  });

  factory PedidoAbono.fromJson(Map<String, dynamic> json) {
    DateTime? fechaParsed;
    if (json['fecha'] != null || json['created_at'] != null) {
      fechaParsed = DateTime.tryParse(
          json['fecha']?.toString() ?? json['created_at']?.toString() ?? '');
    }

    return PedidoAbono(
      id: parseInt(json['id']),
      monto: parseDouble(json['monto']),
      metodoPago: json['metodoPago']?.toString() ??
          json['metodo_pago']?.toString() ??
          'EFECTIVO',
      nota: json['nota']?.toString(),
      fecha: fechaParsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'monto': monto,
      'metodoPago': metodoPago,
      if (nota != null) 'nota': nota,
      if (fecha != null) 'fecha': fecha!.toIso8601String(),
    };
  }

  PedidoAbono copyWith({
    int? id,
    double? monto,
    String? metodoPago,
    String? nota,
    DateTime? fecha,
  }) {
    return PedidoAbono(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      nota: nota ?? this.nota,
      fecha: fecha ?? this.fecha,
    );
  }

  @override
  List<Object?> get props => [id, monto, metodoPago, nota, fecha];
}
