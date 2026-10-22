import 'package:flutter/material.dart';

/// Radios de borde estándar del sistema SGI-U.
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.4.
abstract final class AppRadii {
  static const double radioMinimo = 4;
  static const double radioChico = 8;

  /// Radio de controles chicos (caja de cantidad del POS).
  static const double radioControl = 6;
  static const double radioTarjeta = 12;
  static const double radioCampo = 16;
  static const double radioBoton = 18;
  static const double radioPanel = 32;
  static const double radioPildora = 999;

  static const BorderRadius bordeMinimo =
      BorderRadius.all(Radius.circular(radioMinimo));
  static const BorderRadius bordeChico =
      BorderRadius.all(Radius.circular(radioChico));
  static const BorderRadius bordeControl =
      BorderRadius.all(Radius.circular(radioControl));
  static const BorderRadius bordeTarjeta =
      BorderRadius.all(Radius.circular(radioTarjeta));
  static const BorderRadius bordeCampo =
      BorderRadius.all(Radius.circular(radioCampo));
  static const BorderRadius bordeBoton =
      BorderRadius.all(Radius.circular(radioBoton));
  static const BorderRadius bordePanel =
      BorderRadius.all(Radius.circular(radioPanel));
  static const BorderRadius bordePildora =
      BorderRadius.all(Radius.circular(radioPildora));
}
