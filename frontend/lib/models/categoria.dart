/// Categoría de producto: etiqueta de Sandra para filtrar y para reportes.
/// No decide comportamiento (eso lo hace el tipo de artículo).
class Categoria {
  final int id;
  final String nombre;

  const Categoria({required this.id, required this.nombre});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre']?.toString() ?? '',
      );
}
