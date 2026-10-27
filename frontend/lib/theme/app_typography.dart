import 'package:flutter/material.dart';

/// Escala tipográfica del sistema SGI-U.
///
/// Colapsa los 19 tamaños sueltos a 10 pasos. Los estilos no fijan color
/// (lo aporta el `Theme`/el widget que los usa) ni `height` (se conserva el
/// interlineado por defecto para no alterar layouts existentes).
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.2.
abstract final class AppTypography {
  /// Nombre del negocio / display (absorbe 36–54).
  static const TextStyle marca =
      TextStyle(fontSize: 40, fontWeight: FontWeight.w700);

  /// Título de pantalla/sección (absorbe 28–32).
  static const TextStyle tituloPantalla =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w700);

  /// Número grande de una tarjeta KPI.
  static const TextStyle numeroKpi =
      TextStyle(fontSize: 26, fontWeight: FontWeight.w700);

  /// Número destacado de una tarjeta KPI principal (dashboard/balance).
  static const TextStyle numeroKpiGrande =
      TextStyle(fontSize: 36, fontWeight: FontWeight.w700);

  /// Número de una tarjeta de resumen financiera (dashboard).
  static const TextStyle numeroKpiMediano =
      TextStyle(fontSize: 32, fontWeight: FontWeight.w700);

  /// Número de una tarjeta de total (movimientos, versión chica).
  static const TextStyle numeroResumen =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700);

  /// Encabezado de tarjeta/modal (absorbe 20–24).
  static const TextStyle tituloTarjeta =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  /// Bajada / subtítulo.
  static const TextStyle subtitulo =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  /// Texto general.
  static const TextStyle texto =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400);

  /// Texto secundario (absorbe 14–15).
  static const TextStyle textoChico =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  /// Etiquetas, campos y botones (absorbe 12–13).
  static const TextStyle etiqueta =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  /// Notas / caption (absorbe 10–11).
  static const TextStyle pie =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w400);

  /// Texto micro (absorbe 7–9).
  static const TextStyle micro =
      TextStyle(fontSize: 8, fontWeight: FontWeight.w400);
}
