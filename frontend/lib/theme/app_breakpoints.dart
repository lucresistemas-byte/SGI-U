/// Puntos de corte responsive del sistema SGI-U.
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.6.
abstract final class AppBreakpoints {
  /// Móvil / escritorio. Reemplaza el `900` suelto y `esMobile()`.
  static const double corteMovil = 900;

  /// Colapso del menú lateral.
  static const double corteMenuColapsado = 180;

  /// Tarjetas y grids compactos.
  static const double corteCompacto = 500;
}
