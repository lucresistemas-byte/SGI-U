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

  /// MATERIA_PRIMA, INSUMO o REVENTA_MATERIA_PRIMA (define el prefijo del código).
  final String tipo;

  static const tipos = {
    'MATERIA_PRIMA': 'Materia prima',
    'INSUMO': 'Insumo',
    'REVENTA_MATERIA_PRIMA': 'Reventa + materia prima',
  };

  String get descripcionTipo => tipos[tipo] ?? tipo;

  const Insumo({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.costoUnitario,
    this.unidadMedida = 'UNIDAD',
    this.stockActual = 0,
    this.stockMinimo,
    this.activo = true,
    this.tipo = 'MATERIA_PRIMA',
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
      tipo: json['tipo']?.toString() ?? 'MATERIA_PRIMA',
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
      'tipo': tipo,
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
    String? tipo,
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
      tipo: tipo ?? this.tipo,
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
        tipo,
      ];
}
