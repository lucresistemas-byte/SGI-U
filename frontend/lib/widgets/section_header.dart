import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Encabezado de pantalla/sección: título, bajada opcional y una acción a la
/// derecha (p. ej. el botón "Nuevo…"). Reemplaza los títulos escritos a mano
/// en cada sección.
class SectionHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  const SectionHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: AppTypography.tituloPantalla
                    .copyWith(color: AppColors.textoPrincipal),
              ),
              if (subtitulo != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.espacioMinimo),
                  child: Text(
                    subtitulo!,
                    style: AppTypography.textoChico
                        .copyWith(color: AppColors.textoSecundario),
                  ),
                ),
            ],
          ),
        ),
        if (accion != null) ...[
          const SizedBox(width: AppSpacing.espacioEstandar),
          accion!,
        ],
      ],
    );
  }
}
