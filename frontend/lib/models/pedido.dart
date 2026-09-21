import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';
import 'pedido_abono.dart';

class Pedido extends Equatable {
  final int? id;
  final String clienteNombre;
  final String clienteTelefono;
  final String descripcion;
  final double montoTotal;
  final double senia;
  final double saldo;
  final String estado;
  final DateTime? fechaCreacion;
  final DateTime? fechaEntrega;
  final List<PedidoAbono> abonos;
  final bool activo;

  const Pedido({
    this.id,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.descripcion,
    required this.montoTotal,
    this.senia = 0.0,
    double? saldo,
    this.estado = 'PENDIENTE',
    this.fechaCreacion,
    this.fechaEntrega,
    this.abonos = const [],
    this.activo = true,
  }) : saldo = saldo ?? (montoTotal - senia);

  /// Máquina de estados del pedido para visualización y lógica de negocio:
  /// - Cancelado: si el pedido fue cancelado
  /// - Pagado: saldo 0 o estado PAGADO
  /// - Parcialmente Pagado: se registró seña o abono pero aún resta saldo
  /// - Pendiente: no se registró ningún pago inicial (saldo == total)
  String get estadoCalculado {
    if (estado.toUpperCase() == 'CANCELADO') {
      return 'Cancelado';
    }
    if (saldo <= 0.001 || estado.toUpperCase() == 'PAGADO') {
      return 'Pagado';
    }
    final totalPagado = montoTotal - saldo;
    if (totalPagado > 0.001 && saldo > 0.001) {
      return 'Parcialmente Pagado';
    }
    return 'Pendiente';
  }

  double get totalPagado => montoTotal - saldo;

  factory Pedido.fromJson(Map<String, dynamic> json) {
    List<PedidoAbono> abonosList = [];
    if (json['abonos'] is List) {
      abonosList = (json['abonos'] as List)
          .map((a) => PedidoAbono.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
    }

    DateTime? fechaCreacionParsed;
    final rawCreacion = json['fechaCreacion'] ?? json['created_at'];
    if (rawCreacion != null) {
      fechaCreacionParsed = DateTime.tryParse(rawCreacion.toString());
    }

    DateTime? fechaEntregaParsed;
    final rawEntrega = json['fechaEntrega'] ?? json['fecha_entrega'];
    if (rawEntrega != null) {
      fechaEntregaParsed = DateTime.tryParse(rawEntrega.toString());
    }

    final total = parseDouble(json['montoTotal'] ?? json['monto_total']);
    final sen = parseDouble(json['senia'] ?? json['seña']);
    final sal = json['saldo'] != null
        ? parseDouble(json['saldo'])
        : (total - sen);

    return Pedido(
      id: parseInt(json['id']),
      clienteNombre: json['clienteNombre']?.toString() ??
          json['cliente_nombre']?.toString() ??
          '',
      clienteTelefono: json['clienteTelefono']?.toString() ??
          json['cliente_telefono']?.toString() ??
          '',
      descripcion: json['descripcion']?.toString() ?? '',
      montoTotal: total,
      senia: sen,
      saldo: sal,
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      fechaCreacion: fechaCreacionParsed,
      fechaEntrega: fechaEntregaParsed,
      abonos: abonosList,
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clienteNombre': clienteNombre,
      'clienteTelefono': clienteTelefono,
      'descripcion': descripcion,
      'montoTotal': montoTotal,
      'senia': senia,
      'saldo': saldo,
      'estado': estado,
      if (fechaCreacion != null) 'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaEntrega != null) 'fechaEntrega': fechaEntrega!.toIso8601String(),
      'abonos': abonos.map((a) => a.toJson()).toList(),
      'activo': activo,
    };
  }

  Pedido copyWith({
    int? id,
    String? clienteNombre,
    String? clienteTelefono,
    String? descripcion,
    double? montoTotal,
    double? senia,
    double? saldo,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaEntrega,
    List<PedidoAbono>? abonos,
    bool? activo,
  }) {
    final mTotal = montoTotal ?? this.montoTotal;
    final mSaldo = saldo ?? this.saldo;
    return Pedido(
      id: id ?? this.id,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      descripcion: descripcion ?? this.descripcion,
      montoTotal: mTotal,
      senia: senia ?? this.senia,
      saldo: mSaldo,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      abonos: abonos ?? this.abonos,
      activo: activo ?? this.activo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clienteNombre,
        clienteTelefono,
        descripcion,
        montoTotal,
        senia,
        saldo,
        estado,
        fechaCreacion,
        fechaEntrega,
        abonos,
        activo,
      ];
}
