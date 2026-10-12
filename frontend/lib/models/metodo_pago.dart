/// Método de pago configurable (Configuración → Métodos de pago). El fijo es
/// "Efectivo": no se renombra ni se desactiva y es el único con vuelto.
class MetodoPago {
  final int id;
  final String nombre;
  final bool activo;
  final bool fijo;
  final int orden;

  const MetodoPago({
    required this.id,
    required this.nombre,
    this.activo = true,
    this.fijo = false,
    this.orden = 0,
  });

  /// Efectivo: admite vuelto en el POS.
  bool get esEfectivo => fijo;

  factory MetodoPago.fromJson(Map<String, dynamic> json) => MetodoPago(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre']?.toString() ?? '',
        activo: json['activo'] != false,
        fijo: json['fijo'] == true,
        orden: (json['orden'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is MetodoPago &&
      other.id == id &&
      other.nombre == nombre &&
      other.activo == activo &&
      other.fijo == fijo &&
      other.orden == orden;

  @override
  int get hashCode => Object.hash(id, nombre, activo, fijo, orden);
}
