class Product {
  final String codigo;
  final String nombre;
  final double precioUnitario;
  final int stockActual;
  final bool activo;
  final String? categoria;

  Product({
    required this.codigo,
    required this.nombre,
    required this.precioUnitario,
    required this.stockActual,
    this.activo = true,
    this.categoria,
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
    return Product(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      stockActual: json['stockActual'] ?? 0,
      activo: json['activo'] ?? true,
      categoria: cat,
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
    };
  }

  Product copyWith({
    String? codigo,
    String? nombre,
    double? precioUnitario,
    int? stockActual,
    bool? activo,
    String? categoria,
  }) {
    return Product(
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      stockActual: stockActual ?? this.stockActual,
      activo: activo ?? this.activo,
      categoria: categoria ?? this.categoria,
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
          categoria == other.categoria;

  @override
  int get hashCode =>
      codigo.hashCode ^
      nombre.hashCode ^
      precioUnitario.hashCode ^
      stockActual.hashCode ^
      activo.hashCode ^
      categoria.hashCode;
}