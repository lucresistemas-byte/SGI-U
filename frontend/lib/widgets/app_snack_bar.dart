import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Mensajes del sistema con el color de cada estado, en vez de un
/// `backgroundColor` rojo escrito a mano en cada pantalla.
abstract final class AppSnackBar {
  static void exito(BuildContext context, String mensaje) =>
      _mostrar(context, mensaje, AppColors.exito, Icons.check_circle_outline);

  static void error(BuildContext context, String mensaje) =>
      _mostrar(context, mensaje, AppColors.error, Icons.error_outline);

  static void info(BuildContext context, String mensaje) =>
      _mostrar(context, mensaje, AppColors.info, Icons.info_outline);

  static void _mostrar(
    BuildContext context,
    String mensaje,
    Color color,
    IconData icono,
  ) {
    if (mensaje.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icono, color: AppColors.sobreMarca, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensaje,
                  style: AppTypography.textoChico
                      .copyWith(color: AppColors.sobreMarca),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
