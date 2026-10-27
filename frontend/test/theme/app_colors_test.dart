import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgi_u_frontend/theme/app_colors.dart';

/// Canal linealizado (WCAG 2.1). Acepta el valor 0..1 de [Color.r]/[Color.g].
double _canal(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminancia(Color color) =>
    0.2126 * _canal(color.r) + 0.7152 * _canal(color.g) + 0.0722 * _canal(color.b);

/// Relación de contraste WCAG entre un texto y su fondo.
double _contraste(Color texto, Color fondo) {
  final a = _luminancia(texto);
  final b = _luminancia(fondo);
  final claro = math.max(a, b);
  final oscuro = math.min(a, b);
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  group('AppColors — tokens canónicos', () {
    test('expone la paleta por función', () {
      expect(AppColors.marca, const Color(0xFF006B3D));
      expect(AppColors.marcaAcento, const Color(0xFF008A3D));
      expect(AppColors.marcaActiva, const Color(0xFF004D40));
      expect(AppColors.seleccionFondo, const Color(0xFFC8E6C9));
      expect(AppColors.exito, const Color(0xFF15803D));
      expect(AppColors.error, const Color(0xFFD32F2F));
      expect(AppColors.alerta, const Color(0xFFB45309));
      expect(AppColors.info, const Color(0xFF0284C7));
      expect(AppColors.textoPrincipal, const Color(0xFF1E293B));
      expect(AppColors.fondoApp, const Color(0xFFF1F5F9));
    });

    test('los alias de compatibilidad apuntan a los tokens nuevos', () {
      expect(AppColors.verdePrincipal, AppColors.marca);
      expect(AppColors.verdeClaro, AppColors.marcaAcento);
      expect(AppColors.verdeTeal, AppColors.marcaActiva);
      expect(AppColors.rojoEgresos, AppColors.error);
      expect(AppColors.grisFondo, AppColors.fondoApp);
    });
  });

  group('AppColors — contraste WCAG AA', () {
    const fondo = AppColors.fondoSuperficie;

    test('texto sobre superficie ≥ 4.5:1', () {
      expect(_contraste(AppColors.textoPrincipal, fondo),
          greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.textoSecundario, fondo),
          greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.textoTerciario, fondo),
          greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.textoInactivo, fondo),
          greaterThanOrEqualTo(4.5));
    });

    test('colores de acción/estado sobre superficie ≥ 4.5:1', () {
      expect(_contraste(AppColors.marca, fondo), greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.marcaActiva, fondo),
          greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.exito, fondo), greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.error, fondo), greaterThanOrEqualTo(4.5));
      expect(_contraste(AppColors.alerta, fondo), greaterThanOrEqualTo(4.5));
    });

    test('texto sobre marca ≥ 4.5:1', () {
      expect(_contraste(AppColors.sobreMarca, AppColors.marca),
          greaterThanOrEqualTo(4.5));
    });

    test('info se usa como acento/ícono: ≥ 3:1 (no como texto normal)', () {
      expect(_contraste(AppColors.info, fondo), greaterThanOrEqualTo(3.0));
    });
  });
}
