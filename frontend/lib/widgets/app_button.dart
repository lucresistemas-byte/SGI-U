import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botones del sistema. El estilo base sale del `Theme` (`ElevatedButtonTheme`,
/// `OutlinedButtonTheme`, `TextButtonTheme`); acá solo se elige la variante
/// semántica. [danger] sobreescribe el color con [AppColors.error].
abstract final class AppButton {
  static Widget primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icono,
  }) =>
      ElevatedButton(
        key: key,
        onPressed: onPressed,
        child: _conIcono(icono, child),
      );

  static Widget secondary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icono,
  }) =>
      OutlinedButton(
        key: key,
        onPressed: onPressed,
        child: _conIcono(icono, child),
      );

  static Widget ghost({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icono,
  }) =>
      TextButton(
        key: key,
        onPressed: onPressed,
        child: _conIcono(icono, child),
      );

  static Widget danger({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icono,
  }) =>
      ElevatedButton(
        key: key,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.sobreMarca,
        ),
        child: _conIcono(icono, child),
      );

  static Widget _conIcono(IconData? icono, Widget child) {
    if (icono == null) return child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18),
        const SizedBox(width: 8),
        Flexible(child: child),
      ],
    );
  }
}
