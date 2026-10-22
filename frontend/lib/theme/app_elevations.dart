import 'package:flutter/material.dart';

/// Elevaciones y sombras estándar del sistema SGI-U.
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.5.
abstract final class AppElevations {
  /// Tarjetas planas (borde en vez de sombra).
  static const double sombraTarjeta = 0;

  /// Sombra suave de tarjeta (tarjetas de resumen/KPI con elevación sutil).
  static const List<BoxShadow> sombraTarjetaSuave = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  /// Modales y overlays.
  static const double sombraModal = 4;

  /// Panel grande (login).
  static const List<BoxShadow> sombraPanel = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, spreadRadius: 2),
  ];
}
