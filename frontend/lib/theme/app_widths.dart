/// Anchos fijos del sistema SGI-U.
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.7.
abstract final class AppWidths {
  static const double anchoMenuExpandido = 260;
  static const double anchoMenuColapsado = 80;

  /// Proporción del ancho de pantalla que ocupa el drawer en móvil, acotada
  /// entre [anchoDrawerMin] y [anchoDrawerMax].
  static const double proporcionDrawer = 0.70;
  static const double anchoDrawerMin = 280;
  static const double anchoDrawerMax = 320;

  static const double anchoModalChico = 420;
  static const double anchoModalMedio = 520;
  static const double anchoModalGrande = 680;
}
