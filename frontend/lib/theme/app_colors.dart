import 'package:flutter/material.dart';

/// Paleta del sistema SGI-U.
///
/// Los nombres son **por función**, no por color: si la paleta cambia (incluso
/// si deja de ser verde) los nombres siguen siendo válidos. No hay prefijo
/// `color` (la clase `AppColors` ya lo dice).
///
/// Especificación: `frontend/context/TIPIFICACION_ESTILOS.md` §1.1.
abstract final class AppColors {
  // --- Marca y acción ---
  /// Acción principal / marca.
  static const Color marca = Color(0xFF006B3D);

  /// Acento de marca (progreso, secundario).
  static const Color marcaAcento = Color(0xFF008A3D);

  /// Marca en estado activo (tabs, check, ítem seleccionado).
  static const Color marcaActiva = Color(0xFF004D40);

  /// Texto e íconos sobre [marca]/[marcaActiva].
  static const Color sobreMarca = Color(0xFFFFFFFF);

  /// Fondo de una selección (chip elegido, ítem de menú).
  static const Color seleccionFondo = Color(0xFFC8E6C9);

  /// Indicador de estado activo.
  static const Color estadoActivo = Color(0xFF2E7D32);

  // --- Texto ---
  static const Color textoPrincipal = Color(0xFF1E293B);
  static const Color textoSecundario = Color(0xFF475569);
  static const Color textoTerciario = Color(0xFF666666);
  static const Color textoInactivo = Color(0xFF64748B);

  // --- Superficies y bordes ---
  static const Color fondoSuperficie = Color(0xFFFFFFFF);
  static const Color fondoApp = Color(0xFFF1F5F9);
  static const Color fondoMenu = Color(0xFFF8F9FA);
  static const Color fondoAlternativo = Color(0xFFF5F5F5);
  static const Color borde = Color(0xFFE5E5E5);
  static const Color bordeSuave = Color(0xFFE2E8F0);
  static const Color menuTexto = Color(0xFF455A64);

  // --- Estados ---
  static const Color exito = Color(0xFF15803D);
  static const Color exitoFondo = Color(0xFFEAF8EF);
  static const Color error = Color(0xFFD32F2F);
  static const Color alerta = Color(0xFFB45309);
  static const Color alertaFondo = Color(0xFFFFE0B2);
  static const Color info = Color(0xFF0284C7);
  static const Color transparente = Color(0x00000000);

  // --- Compatibilidad temporal (la Etapa 2 migra los usos y las borra) ---
  static const Color verdePrincipal = marca;
  static const Color verdeClaro = marcaAcento;
  static const Color verdeTeal = marcaActiva;
  static const Color verdeActivo = estadoActivo;
  static const Color grisVerdeClaro = seleccionFondo;
  static const Color rojoEgresos = error;
  static const Color grisTexto = textoTerciario;
  static const Color grisInactivo = textoInactivo;
  static const Color grisFondo = fondoApp;
  static const Color grisFondoAlternativo = fondoAlternativo;
  static const Color grisMenu = fondoMenu;
  static const Color grisMenuDark = menuTexto;
  static const Color grisBorde = borde;
  static const Color grisInformativo = bordeSuave;
  static const Color blanco = fondoSuperficie;
  static const Color negro = textoPrincipal;
}
