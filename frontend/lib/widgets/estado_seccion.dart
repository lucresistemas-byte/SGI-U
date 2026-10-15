import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Estado vacío de una sección (no hay datos): ícono, mensaje y acción
/// opcional.
class EmptyState extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final Widget? accion;

  const EmptyState({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.espacioPantalla),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: AppColors.textoInactivo),
            const SizedBox(height: AppSpacing.espacioEstandar),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style:
                  AppTypography.texto.copyWith(color: AppColors.textoSecundario),
            ),
            if (accion != null) ...[
              const SizedBox(height: AppSpacing.espacioSeccion),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error de una sección: mensaje y botón "Reintentar" opcional.
class ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const ErrorState({
    super.key,
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.espacioPantalla),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.espacioEstandar),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTypography.texto.copyWith(color: AppColors.error),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: AppSpacing.espacioSeccion),
              AppButton.secondary(
                onPressed: onReintentar,
                icono: Icons.refresh,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
