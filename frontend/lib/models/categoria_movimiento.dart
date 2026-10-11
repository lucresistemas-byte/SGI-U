/// Categorías para dar de alta un movimiento, según su tipo. El código es lo
/// que se guarda y valida el backend (CategoriaMovimiento.java); la etiqueta
/// es lo que ve el usuario.
class CategoriaMovimiento {
  final String codigo;
  final String etiqueta;

  const CategoriaMovimiento(this.codigo, this.etiqueta);

  static const ingreso = [
    CategoriaMovimiento('VENTA', 'Venta'),
    CategoriaMovimiento('OTRO_INGRESO', 'Otro ingreso'),
  ];

  static const egreso = [
    CategoriaMovimiento('COMPRA', 'Compra'),
    CategoriaMovimiento('SERVICIOS', 'Servicios'),
    CategoriaMovimiento('ALQUILER', 'Alquiler'),
    CategoriaMovimiento('SUELDOS', 'Sueldos'),
    CategoriaMovimiento('OTRO', 'Otro'),
  ];

  /// [tipo]: 'Ingreso'/'INGRESO' o 'Egreso'/'EGRESO'.
  static List<CategoriaMovimiento> paraTipo(String tipo) =>
      tipo.toUpperCase() == 'EGRESO' ? egreso : ingreso;

  /// Etiqueta de un código actual; los valores de movimientos anteriores
  /// (SERVICIO, PROVEEDOR, ...) se muestran tal cual.
  static String etiquetaDe(String? categoria) {
    if (categoria == null || categoria.trim().isEmpty) return 'Sin categoría';
    for (final c in [...ingreso, ...egreso]) {
      if (c.codigo == categoria) return c.etiqueta;
    }
    return categoria;
  }
}
