import 'package:equatable/equatable.dart';
import '../utils/parsers.dart';
import 'unidad_medida.dart';

/// Artículo de Materia Prima: materia prima, insumo o reventa + materia
/// prima (filas del catálogo único). Stock y costo se guardan en la unidad
/// base de su familia (gramo, mililitro, centímetro o unidad); [unidadMedida]
/// es la unidad en que se muestra.
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

  // Reventa + materia prima: se vende por unidades enteras ("Caja" de 100 g).
  final String? ventaUnidadNombre;

  /// Contenido de la unidad de venta en unidad base.
  final double? ventaUnidadContenido;

  /// Unidades de venta enteras en stock (lo que ofrece el POS).
  final int? stockUnidadesVenta;

  /// Lo que queda suelto, en unidad base (p. ej. 50 g).
  final double? stockSuelto;
  final double? costoUnidadVenta;
  final double? porcentajeGanancia;
  final double? precioVenta;

  /// MARGEN (costo × (1 + %)) o MANUAL (precio fijado a mano, nunca por debajo del %).
  final String? modoPrecio;

  /// Ganancia por unidad de venta en pesos: precio − costo.
  final double? gananciaPesos;

  bool get precioManual => modoPrecio == 'MANUAL';

  /// Preparación base usada como componente de receta (viene de /api/recetas/componentes).
  bool get esPreparacionBase => tipo == 'ELABORADO';
  final int? categoriaId;

  static const tipos = {
    'MATERIA_PRIMA': 'Materia prima',
    'INSUMO': 'Insumo',
    'REVENTA_MATERIA_PRIMA': 'Reventa + materia prima',
  };

  String get descripcionTipo => tipo == 'ELABORADO' ? 'Preparación base' : (tipos[tipo] ?? tipo);

  bool get esReventaMateriaPrima => tipo == 'REVENTA_MATERIA_PRIMA';

  /// Cantidad de la presentación de compra en unidad base (null si no hay).
  double? get presentacionEnBase {
    final u = UnidadMedida.deCodigo(presentacionUnidad);
    final c = presentacionCantidad;
    return u == null || c == null ? null : u.aBase(c);
  }

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
    this.ventaUnidadNombre,
    this.ventaUnidadContenido,
    this.stockUnidadesVenta,
    this.stockSuelto,
    this.costoUnidadVenta,
    this.porcentajeGanancia,
    this.precioVenta,
    this.modoPrecio,
    this.gananciaPesos,
    this.categoriaId,
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
      ventaUnidadNombre: json['ventaUnidadNombre']?.toString(),
      ventaUnidadContenido: _doble(json['ventaUnidadContenido']),
      stockUnidadesVenta: json['stockUnidadesVenta'] != null ? parseInt(json['stockUnidadesVenta']) : null,
      stockSuelto: _doble(json['stockSuelto']),
      costoUnidadVenta: _doble(json['costoUnidadVenta']),
      porcentajeGanancia: _doble(json['porcentajeGanancia']),
      precioVenta: _doble(json['precioVenta']),
      modoPrecio: json['modoPrecio']?.toString(),
      gananciaPesos: _doble(json['gananciaPesos']),
      categoriaId: json['categoriaId'] != null ? parseInt(json['categoriaId']) : null,
    );
  }

  static double? _doble(dynamic v) => v != null ? parseDouble(v) : null;

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
      if (ventaUnidadNombre != null) 'ventaUnidadNombre': ventaUnidadNombre,
      if (ventaUnidadContenido != null) 'ventaUnidadContenido': ventaUnidadContenido,
      if (stockUnidadesVenta != null) 'stockUnidadesVenta': stockUnidadesVenta,
      if (stockSuelto != null) 'stockSuelto': stockSuelto,
      if (costoUnidadVenta != null) 'costoUnidadVenta': costoUnidadVenta,
      if (porcentajeGanancia != null) 'porcentajeGanancia': porcentajeGanancia,
      if (precioVenta != null) 'precioVenta': precioVenta,
      if (modoPrecio != null) 'modoPrecio': modoPrecio,
      if (gananciaPesos != null) 'gananciaPesos': gananciaPesos,
      if (categoriaId != null) 'categoriaId': categoriaId,
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
      ventaUnidadNombre: ventaUnidadNombre,
      ventaUnidadContenido: ventaUnidadContenido,
      stockUnidadesVenta: stockUnidadesVenta,
      stockSuelto: stockSuelto,
      costoUnidadVenta: costoUnidadVenta,
      porcentajeGanancia: porcentajeGanancia,
      precioVenta: precioVenta,
      modoPrecio: modoPrecio,
      gananciaPesos: gananciaPesos,
      categoriaId: categoriaId,
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
        ventaUnidadNombre,
        ventaUnidadContenido,
        stockUnidadesVenta,
        stockSuelto,
        costoUnidadVenta,
        porcentajeGanancia,
        precioVenta,
        modoPrecio,
        gananciaPesos,
        categoriaId,
      ];
}
