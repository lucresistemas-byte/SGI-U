class Product {
  final String codigo;
  final String nombre;
  final double precioUnitario;
  final int stockActual;
  final bool activo;
  final String? categoria;
  final String? unidadMedida;
  final double? precioCosto;
  final double? porcentajeGanancia;

  Product({
    required this.codigo,
    required this.nombre,
    required this.precioUnitario,
    required this.stockActual,
    this.activo = true,
    this.categoria,
    this.unidadMedida = 'UNIDAD',
    this.precioCosto,
    this.porcentajeGanancia,
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
      activo: json['activo'] ?? true,
      categoria: cat,
      unidadMedida: unidad,
      precioCosto: costo,
      porcentajeGanancia: margen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'precioUnitario': precioUnitario,
      'stockActual': stockActual,
      'activo': activo,
      if (categoria != null) 'categoria': categoria,
      if (unidadMedida != null) 'unidadMedida': unidadMedida,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      if (precioCosto != null) 'precioCosto': precioCosto,
      if (precioCosto != null) 'precio_costo': precioCosto,
      if (porcentajeGanancia != null) 'porcentajeGanancia': porcentajeGanancia,
      if (porcentajeGanancia != null) 'porcentaje_ganancia': porcentajeGanancia,
    };
  }

  Product copyWith({
    String? codigo,
    String? nombre,
    double? precioUnitario,
    int? stockActual,
    bool? activo,
    String? categoria,
    String? unidadMedida,
    double? precioCosto,
    double? porcentajeGanancia,
  }) {
    return Product(
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      stockActual: stockActual ?? this.stockActual,
      activo: activo ?? this.activo,
      categoria: categoria ?? this.categoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioCosto: precioCosto ?? this.precioCosto,
      porcentajeGanancia: porcentajeGanancia ?? this.porcentajeGanancia,
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