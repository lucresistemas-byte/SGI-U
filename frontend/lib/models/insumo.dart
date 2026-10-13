import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';
import 'unidad_medida.dart';

/// Materia prima o insumo. Stock y costo se guardan en la unidad base de su
/// familia (gramo, mililitro, centímetro o unidad); [unidadMedida] es la
/// unidad en que se muestra.
class Insumo extends Equatable {
  final int? id;
  final String codigo;
  final String nombre;

  /// Costo por [unidadMedida] (p. ej. el kilo).
  final double costoUnitario;
  final String unidadMedida;

  /// Stock en unidad base.
  final double stockActual;
  final double? stockMinimo;
  final bool activo;

  /// MATERIA_PRIMA, INSUMO o REVENTA_MATERIA_PRIMA (define el prefijo del código).
  final String tipo;

  /// Costo por unidad base (4 decimales). Si no viene, se deriva del costo
  /// por la unidad para mostrar.
  final double? _costoUnidadBase;

  // Presentación de compra (p. ej. "Bolsa 25 kg": 25 KILO a $30.000).
  final String? presentacionDescripcion;
  final double? presentacionCantidad;
  final String? presentacionUnidad;
  final double? presentacionPrecio;

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
    double? costoUnidadBase,
    this.presentacionDescripcion,
    this.presentacionCantidad,
    this.presentacionUnidad,
    this.presentacionPrecio,
  }) : _costoUnidadBase = costoUnidadBase;

  /// Unidad para mostrar (UNIDAD si no se reconoce).
  UnidadMedida get unidad => UnidadMedida.deCodigo(unidadMedida) ?? UnidadMedida.unidad;

  FamiliaUnidad get familia => unidad.familia ?? FamiliaUnidad.unidad;

  double get costoUnidadBase => _costoUnidadBase ?? costoUnitario / unidad.factor;

  /// Costo de una unidad de la familia (p. ej. 1 g, 1 kg).
  double costoPor(UnidadMedida u) => costoUnidadBase * u.factor;

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      costoUnitario: parseDouble(json['costoUnitario'] ?? json['costo_unitario']),
      unidadMedida: json['unidadMedida']?.toString() ?? json['unidad_medida']?.toString() ?? 'UNIDAD',
      stockActual: parseDouble(json['stockActual'] ?? json['stock_actual']),
      stockMinimo: json['stockMinimo'] != null ? parseDouble(json['stockMinimo']) : null,
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == null,
      tipo: json['tipo']?.toString() ?? 'MATERIA_PRIMA',
      costoUnidadBase: json['costoUnidadBase'] != null ? parseDouble(json['costoUnidadBase']) : null,
      presentacionDescripcion: json['presentacionDescripcion']?.toString(),
      presentacionCantidad:
          json['presentacionCantidad'] != null ? parseDouble(json['presentacionCantidad']) : null,
      presentacionUnidad: json['presentacionUnidad']?.toString(),
      presentacionPrecio: json['presentacionPrecio'] != null ? parseDouble(json['presentacionPrecio']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'costoUnitario': costoUnitario,
      'costoUnidadBase': costoUnidadBase,
      'unidadMedida': unidadMedida,
      'stockActual': stockActual,
      if (stockMinimo != null) 'stockMinimo': stockMinimo,
      'activo': activo,
      'tipo': tipo,
      if (presentacionDescripcion != null) 'presentacionDescripcion': presentacionDescripcion,
      if (presentacionCantidad != null) 'presentacionCantidad': presentacionCantidad,
      if (presentacionUnidad != null) 'presentacionUnidad': presentacionUnidad,
      if (presentacionPrecio != null) 'presentacionPrecio': presentacionPrecio,
    };
  }

  Insumo copyWith({
    int? id,
    String? codigo,
    String? nombre,
    double? costoUnitario,
    String? unidadMedida,
    double? stockActual,
    double? stockMinimo,
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
      costoUnidadBase: costoUnitario == null && unidadMedida == null ? _costoUnidadBase : null,
      presentacionDescripcion: presentacionDescripcion,
      presentacionCantidad: presentacionCantidad,
      presentacionUnidad: presentacionUnidad,
      presentacionPrecio: presentacionPrecio,
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
        _costoUnidadBase,
        presentacionDescripcion,
        presentacionCantidad,
        presentacionUnidad,
        presentacionPrecio,
      ];
}
