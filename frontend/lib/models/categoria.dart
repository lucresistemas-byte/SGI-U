/// Categoría de producto: etiqueta de Sandra para filtrar y para reportes.
/// No decide comportamiento (eso lo hace el tipo de artículo).
class Categoria {
  final int id;
  final String nombre;
  final bool activo;

  const Categoria({required this.id, required this.nombre, this.activo = true});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre']?.toString() ?? '',
        activo: json['activo'] != false,
      );
}
