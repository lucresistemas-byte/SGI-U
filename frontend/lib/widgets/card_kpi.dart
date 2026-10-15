import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tarjeta de resumen / KPI: rótulo, número grande y texto de apoyo opcional
/// (p. ej. [ExplicacionMonto]). Absorbe el patrón que hoy se repite en cada
/// pantalla de totales.
class CardKpi extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color? colorValor;
  final Widget? pie;
  final IconData? icono;

  const CardKpi({
    super.key,
    required this.titulo,
    required this.valor,
    this.colorValor,
    this.pie,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.espacioEstandar),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 18, color: AppColors.textoSecundario),
                  const SizedBox(width: AppSpacing.espacioChico),
                ],
                Expanded(
                  child: Text(
                    titulo,
                    style: AppTypography.etiqueta
                        .copyWith(color: AppColors.textoSecundario),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.espacioChico),
            Text(
              valor,
              style: AppTypography.numeroKpi.copyWith(
                color: colorValor ?? AppColors.textoPrincipal,
              ),
            ),
            if (pie != null) ...[
              const SizedBox(height: AppSpacing.espacioMinimo),
              pie!,
            ],
          ],
        ),
      ),
    );
  }
}
