import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tono semántico de un [EstadoChip].
enum TonoEstado { exito, error, alerta, info, neutro }

/// Etiqueta de estado (activo, inactivo, stock, estado de pedido) con el color
/// del tema según [tono]. Reemplaza los `Container`/`Text` con colores a mano.
class EstadoChip extends StatelessWidget {
  final String etiqueta;
  final TonoEstado tono;
  final IconData? icono;

  const EstadoChip({
    super.key,
    required this.etiqueta,
    this.tono = TonoEstado.neutro,
    this.icono,
  });

  ({Color texto, Color fondo}) get _colores => switch (tono) {
        TonoEstado.exito => (texto: AppColors.exito, fondo: AppColors.exitoFondo),
        TonoEstado.error =>
          (texto: AppColors.error, fondo: AppColors.error.withValues(alpha: 0.12)),
        TonoEstado.alerta =>
          (texto: AppColors.alerta, fondo: AppColors.alertaFondo),
        TonoEstado.info =>
          (texto: AppColors.info, fondo: AppColors.info.withValues(alpha: 0.12)),
        TonoEstado.neutro =>
          (texto: AppColors.textoSecundario, fondo: AppColors.fondoAlternativo),
      };

  @override
  Widget build(BuildContext context) {
    final colores = _colores;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.espacioMedio,
        vertical: AppSpacing.espacioMinimo,
      ),
      decoration: BoxDecoration(
        color: colores.fondo,
        borderRadius: AppRadii.bordePildora,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: colores.texto),
            const SizedBox(width: AppSpacing.espacioMinimo),
          ],
          Text(
            etiqueta,
            style: AppTypography.etiqueta
                .copyWith(color: colores.texto, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
