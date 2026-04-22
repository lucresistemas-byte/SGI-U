class Product {
  final String codigo;
  final String nombre;
  final double precioUnitario;
  final int stockActual;

  Product({
    required this.codigo,
    required this.nombre,
    required this.precioUnitario,
    required this.stockActual,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      codigo: json['codigo'],
      nombre: json['nombre'],
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      stockActual: json['stockActual'],
    );
  }
}