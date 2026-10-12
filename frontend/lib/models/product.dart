class Product {
  final String codigo;
  final String nombre;
  final double precioUnitario;
  final int stockActual;

  /// Aviso de stock bajo (articulos_stock.stock_minimo).
  final int stockMinimo;
  final bool activo;
  final String? categoria;
  final String? unidadMedida;
  final double? precioCosto;
  final double? porcentajeGanancia;

  /// Tipo de artículo (ELABORADO, REVENTA, ...): decide el comportamiento,
  /// nunca la categoría. Ver docs/MODELO_PRODUCTOS.md.
  final String tipo;

  /// false = preparación base (un ELABORADO que no se vende).
  final bool vendible;

  static const tiposVendibles = {'ELABORADO', 'REVENTA', 'REVENTA_MATERIA_PRIMA', 'PAQUETE'};

  /// Se muestra y se puede vender en el POS.
  bool get esVendibleEnPos => activo && tiposVendibles.contains(tipo) && vendible;

  bool get esElaborado => tipo == 'ELABORADO';

  bool get esPreparacionBase => esElaborado && !vendible;

  Product({
    required this.codigo,
    required this.nombre,
    required this.precioUnitario,
    required this.stockActual,
    this.stockMinimo = 0,
    this.activo = true,
    this.categoria,
    this.unidadMedida = 'UNIDAD',
    this.precioCosto,
    this.porcentajeGanancia,
    this.tipo = 'REVENTA',
    this.vendible = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? cat;
    if (json['categoria'] != null) {
      if (json['categoria'] is Map) {
        cat = json['categoria']['nombre']?.toString();
      } else {
        cat = json['categoria'].toString();
      }
    }
    final rawUnidad = json['unidadMedida'] ?? json['unidad_medida'];
    final unidad = rawUnidad != null ? rawUnidad.toString() : 'UNIDAD';
    final costo = (json['precioCosto'] ?? json['precio_costo'] as num?)?.toDouble();
    final margen = (json['porcentajeGanancia'] ?? json['porcentaje_ganancia'] as num?)?.toDouble();

    return Product(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      stockActual: json['stockActual'] ?? 0,
      stockMinimo: (json['stockMinimo'] as num?)?.toInt() ?? 0,
      activo: json['activo'] ?? true,
      categoria: cat,
      unidadMedida: unidad,
      precioCosto: costo,
      porcentajeGanancia: margen,
      tipo: json['tipo']?.toString() ?? 'REVENTA',
      vendible: json['vendible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'precioUnitario': precioUnitario,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'activo': activo,
      if (categoria != null) 'categoria': categoria,
      if (unidadMedida != null) 'unidadMedida': unidadMedida,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      if (precioCosto != null) 'precioCosto': precioCosto,
      if (precioCosto != null) 'precio_costo': precioCosto,
      if (porcentajeGanancia != null) 'porcentajeGanancia': porcentajeGanancia,
      if (porcentajeGanancia != null) 'porcentaje_ganancia': porcentajeGanancia,
      'tipo': tipo,
      'vendible': vendible,
    };
  }

  Product copyWith({
    String? codigo,
    String? nombre,
    double? precioUnitario,
    int? stockActual,
    int? stockMinimo,
    bool? activo,
    String? categoria,
    String? unidadMedida,
    double? precioCosto,
    double? porcentajeGanancia,
    String? tipo,
    bool? vendible,
  }) {
    return Product(
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      activo: activo ?? this.activo,
      categoria: categoria ?? this.categoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioCosto: precioCosto ?? this.precioCosto,
      porcentajeGanancia: porcentajeGanancia ?? this.porcentajeGanancia,
      tipo: tipo ?? this.tipo,
      vendible: vendible ?? this.vendible,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          codigo == other.codigo &&
          nombre == other.nombre &&
          precioUnitario == other.precioUnitario &&
          stockActual == other.stockActual &&
          stockMinimo == other.stockMinimo &&
          activo == other.activo &&
          categoria == other.categoria &&
          unidadMedida == other.unidadMedida &&
          precioCosto == other.precioCosto &&
          porcentajeGanancia == other.porcentajeGanancia;

  @override
  int get hashCode =>
      codigo.hashCode ^
      nombre.hashCode ^
      precioUnitario.hashCode ^
      stockActual.hashCode ^
      activo.hashCode ^
      categoria.hashCode ^
      unidadMedida.hashCode ^
      precioCosto.hashCode ^
      porcentajeGanancia.hashCode;
}