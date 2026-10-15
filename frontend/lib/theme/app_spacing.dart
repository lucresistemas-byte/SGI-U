import 'package:flutter/material.dart';

/// Escala fija de espaciado del sistema SGI-U (base 4).
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.3.
abstract final class AppSpacing {
  static const double espacioMinimo = 4;
  static const double espacioChico = 8;
  static const double espacioMedio = 12;
  static const double espacioEstandar = 16;
  static const double espacioGrande = 20;
  static const double espacioSeccion = 24;
  static const double espacioPantalla = 32;

  static const EdgeInsets todosChico = EdgeInsets.all(espacioChico);
  static const EdgeInsets todosEstandar = EdgeInsets.all(espacioEstandar);
  static const EdgeInsets todosSeccion = EdgeInsets.all(espacioSeccion);
  static const EdgeInsets todosPantalla = EdgeInsets.all(espacioPantalla);

  static const EdgeInsets horizontalEstandar =
      EdgeInsets.symmetric(horizontal: espacioEstandar);
  static const EdgeInsets horizontalSeccion =
      EdgeInsets.symmetric(horizontal: espacioSeccion);
  static const EdgeInsets verticalEstandar =
      EdgeInsets.symmetric(vertical: espacioEstandar);
}
