import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_widths.dart';

/// Tamaños de [AppDialog] (mapean a [AppWidths]).
enum TamanoDialogo { chico, medio, grande }

/// Diálogo estándar del sistema: ancho consistente según [tamano], título,
/// contenido y acciones alineadas. Reemplaza los `AlertDialog` con `SizedBox`
/// de ancho ad-hoc.
class AppDialog extends StatelessWidget {
  final String? titulo;
  final Widget? child;
  final List<Widget> acciones;
  final TamanoDialogo tamano;
  final bool mostrarCerrar;

  const AppDialog({
    super.key,
    this.titulo,
    this.child,
    this.acciones = const [],
    this.tamano = TamanoDialogo.medio,
    this.mostrarCerrar = true,
  });

  double get _ancho => switch (tamano) {
        TamanoDialogo.chico => AppWidths.anchoModalChico,
        TamanoDialogo.medio => AppWidths.anchoModalMedio,
        TamanoDialogo.grande => AppWidths.anchoModalGrande,
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _ancho),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titulo != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo!,
                        style: AppTypography.tituloTarjeta
                            .copyWith(color: AppColors.textoPrincipal),
                      ),
                    ),
                    if (mostrarCerrar)
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: AppColors.textoSecundario,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                  ],
                ),
              if (child != null) ...[
                const SizedBox(height: AppSpacing.espacioMedio),
                child!,
              ],
              if (acciones.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.espacioSeccion),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final accion in acciones) ...[
                      accion,
                      const SizedBox(width: AppSpacing.espacioMedio),
                    ],
                  ]..removeLast(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
