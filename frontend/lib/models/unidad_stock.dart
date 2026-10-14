import '../utils/numeros.dart';
import 'unidad_medida.dart';

/// Unidad en que se carga o ajusta el stock de un artículo de Materia Prima:
/// una unidad de la familia (kilo, gramo...), la presentación de compra
/// ("llegó 1 Bulto de 12 cajas") o la unidad de venta de la reventa + materia
/// prima ("3 Cajas"). [codigo] es lo que se envía a la API.
class UnidadStock {
  static const presentacion = 'PRESENTACION';
  static const unidadVenta = 'UNIDAD_VENTA';

  final String codigo;
  final String nombre;

  /// Cuántas unidades base tiene una (1 kg = 1000 g; 1 caja = 100 g).
  final double factor;

  const UnidadStock(this.codigo, this.nombre, this.factor);

  /// Las unidades de la familia y, si hay datos, la presentación de compra y
  /// la unidad de venta.
  static List<UnidadStock> opciones(
    FamiliaUnidad familia, {
    String? presentacionNombre,
    double? presentacionBase,
    String? ventaNombre,
    double? ventaBase,
  }) {
    return [
      for (final u in familia.unidades) UnidadStock(u.codigo, u.nombre, u.factor),
      if (presentacionBase != null && presentacionBase > 0)
        UnidadStock(presentacion, _conContenido(presentacionNombre ?? 'Presentación de compra',
            presentacionBase, familia), presentacionBase),
      if (ventaBase != null && ventaBase > 0)
        UnidadStock(unidadVenta, _conContenido(ventaNombre ?? 'Unidad de venta', ventaBase, familia), ventaBase),
    ];
  }

  /// "Bulto de 12 cajas (1,2 kg)".
  static String _conContenido(String nombre, double base, FamiliaUnidad familia) =>
      '$nombre (${textoAmigable(base, familia)})';
}
