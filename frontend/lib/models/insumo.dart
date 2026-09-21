import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';

class Insumo extends Equatable {
  final int? id;
  final String codigo;
  final String nombre;
  final double costoUnitario;
  final String unidadMedida;
  final int stockActual;
  final int? stockMinimo;
  final bool activo;

  const Insumo({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.costoUnitario,
    this.unidadMedida = 'UNIDAD',
    this.stockActual = 0,
    this.stockMinimo,
    this.activo = true,
  });

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      costoUnitario: parseDouble(json['costoUnitario'] ?? json['costo_unitario']),
      unidadMedida: json['unidadMedida']?.toString() ?? json['unidad_medida']?.toString() ?? 'UNIDAD',
      stockActual: parseInt(json['stockActual'] ?? json['stock_actual']),
      stockMinimo: json['stockMinimo'] != null ? parseInt(json['stockMinimo']) : null,
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'costoUnitario': costoUnitario,
      'unidadMedida': unidadMedida,
      'stockActual': stockActual,
      if (stockMinimo != null) 'stockMinimo': stockMinimo,
      'activo': activo,
    };
  }

  Insumo copyWith({
    int? id,
    String? codigo,
    String? nombre,
    double? costoUnitario,
    String? unidadMedida,
    int? stockActual,
    int? stockMinimo,
    bool? activo,
  }) {
    return Insumo(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      activo: activo ?? this.activo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        codigo,
        nombre,
        costoUnitario,
        unidadMedida,
        stockActual,
        stockMinimo,
        activo,
      ];
}
