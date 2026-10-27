import 'package:flutter/material.dart';

import '../navigation/transiciones.dart';
import 'app_colors.dart';
import 'app_elevations.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Tema único del sistema SGI-U.
///
/// Se instala una sola vez en `main.dart` (`theme: AppTheme.light`) y absorbe lo
/// que antes se escribía inline (`ColorScheme.fromSeed`, `textTheme`, estilos de
/// componentes). Especificación: `frontend/context/TIPIFICACION_ESTILOS.md`.
abstract final class AppTheme {
  /// Marca canónica (hoy `0xFF006B3D`).
  static const Color semilla = AppColors.marca;

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(seedColor: semilla).copyWith(
      primary: AppColors.marca,
      onPrimary: AppColors.sobreMarca,
      primaryContainer: AppColors.seleccionFondo,
      onPrimaryContainer: AppColors.marcaActiva,
      secondary: AppColors.marcaAcento,
      onSecondary: AppColors.sobreMarca,
      error: AppColors.error,
      onError: AppColors.sobreMarca,
      surface: AppColors.fondoSuperficie,
      onSurface: AppColors.textoPrincipal,
      outline: AppColors.borde,
      outlineVariant: AppColors.bordeSuave,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge:
          AppTypography.marca.copyWith(color: AppColors.textoPrincipal),
      displayMedium:
          AppTypography.marca.copyWith(color: AppColors.textoPrincipal),
      headlineMedium:
          AppTypography.tituloPantalla.copyWith(color: AppColors.textoPrincipal),
      headlineSmall:
          AppTypography.tituloTarjeta.copyWith(color: AppColors.textoPrincipal),
      titleLarge:
          AppTypography.tituloTarjeta.copyWith(color: AppColors.textoPrincipal),
      titleMedium:
          AppTypography.subtitulo.copyWith(color: AppColors.textoPrincipal),
      bodyLarge: AppTypography.texto.copyWith(color: AppColors.textoPrincipal),
      bodyMedium:
          AppTypography.textoChico.copyWith(color: AppColors.textoSecundario),
      bodySmall:
          AppTypography.etiqueta.copyWith(color: AppColors.textoSecundario),
      labelLarge:
          AppTypography.etiqueta.copyWith(color: AppColors.textoPrincipal),
      labelMedium:
          AppTypography.pie.copyWith(color: AppColors.textoSecundario),
      labelSmall:
          AppTypography.micro.copyWith(color: AppColors.textoTerciario),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: AppColors.marca,
      scaffoldBackgroundColor: AppColors.fondoApp,
      canvasColor: AppColors.fondoApp,
      dividerColor: AppColors.borde,
      textTheme: textTheme,
      pageTransitionsTheme: transicionesInstantaneas,

      // --- Barra superior ---
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondoSuperficie,
        foregroundColor: AppColors.textoPrincipal,
        elevation: AppElevations.sombraTarjeta,
        centerTitle: false,
      ),

      // --- Tarjetas ---
      cardTheme: const CardThemeData(
        color: AppColors.fondoSuperficie,
        elevation: AppElevations.sombraTarjeta,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.bordeTarjeta),
      ),

      // --- Diálogos y modales ---
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.fondoSuperficie,
        elevation: AppElevations.sombraModal,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.bordeCampo),
      ),

      // --- Campos de texto ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fondoSuperficie,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: _bordeCampo(AppColors.bordeSuave),
        enabledBorder: _bordeCampo(AppColors.bordeSuave),
        focusedBorder: _bordeCampo(AppColors.marcaAcento, ancho: 1.5),
        errorBorder: _bordeCampo(AppColors.error),
        focusedErrorBorder: _bordeCampo(AppColors.error, ancho: 1.5),
        hintStyle: AppTypography.texto.copyWith(color: AppColors.textoInactivo),
        labelStyle:
            AppTypography.etiqueta.copyWith(color: AppColors.textoSecundario),
      ),

      // --- Botones ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.marca,
          foregroundColor: AppColors.sobreMarca,
          disabledBackgroundColor: AppColors.borde,
          disabledForegroundColor: AppColors.textoInactivo,
          elevation: AppElevations.sombraTarjeta,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.bordeBoton),
          textStyle: AppTypography.etiqueta,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.marca,
          side: const BorderSide(color: AppColors.marcaAcento),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.bordeBoton),
          textStyle: AppTypography.etiqueta,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.marca,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.bordeChico),
          textStyle: AppTypography.etiqueta,
        ),
      ),

      // --- Chips ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.fondoAlternativo,
        selectedColor: AppColors.seleccionFondo,
        side: const BorderSide(color: AppColors.bordeSuave),
        labelStyle:
            AppTypography.etiqueta.copyWith(color: AppColors.textoSecundario),
        secondaryLabelStyle:
            AppTypography.etiqueta.copyWith(color: AppColors.marcaActiva),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.bordeBoton),
      ),

      // --- Mensajes ---
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textoPrincipal,
        contentTextStyle:
            TextStyle(color: AppColors.sobreMarca, fontSize: 14),
        elevation: AppElevations.sombraModal,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.bordeChico),
      ),

      // --- Checkbox y Tooltip ---
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.marca
              : AppColors.fondoSuperficie,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.bordeMinimo),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.textoPrincipal,
          borderRadius: AppRadii.bordeChico,
        ),
        textStyle: AppTypography.etiqueta.copyWith(color: AppColors.sobreMarca),
      ),
    );
  }

  static OutlineInputBorder _bordeCampo(Color color, {double ancho = 1}) =>
      OutlineInputBorder(
        borderRadius: AppRadii.bordeCampo,
        borderSide: BorderSide(color: color, width: ancho),
      );
}
