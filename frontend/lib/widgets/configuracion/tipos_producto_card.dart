import 'package:flutter/material.dart';
import '../../models/tipo_articulo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevations.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Configuración > Tipos de producto: los 6 tipos del sistema, solo lectura.
class TiposProductoCard extends StatelessWidget {
  const TiposProductoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('config_tipos_producto'),
      elevation: AppElevations.sombraTarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.bordeCampo,
        side: BorderSide(color: AppColors.bordeSuave),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.espacioGrande),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipos de producto',
                style: AppTypography.texto.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPrincipal)),
            const SizedBox(height: AppSpacing.espacioMinimo),
            Text(
              'Los tipos son fijos del sistema y deciden cómo se comporta cada producto. '
              'Las categorías son sus propias etiquetas para filtrar y para los reportes.',
              style: AppTypography.etiqueta
                  .copyWith(color: AppColors.textoInactivo),
            ),
            const SizedBox(height: AppSpacing.espacioMedio),
            for (final t in TipoArticuloInfo.todos) _tipo(t),
          ],
        ),
      ),
    );
  }

  Widget _tipo(TipoArticuloInfo t) {
    final estiloSecundario =
        AppTypography.texto.copyWith(color: AppColors.textoSecundario);
    return Padding(
      key: Key('tipo_info_${t.codigo}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.espacioChico),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nombre,
              style: AppTypography.texto.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.textoPrincipal)),
          Text(t.queEs),
          Text('Se vende en el punto de venta: ${t.seVende}',
              style: estiloSecundario),
          Text('Se usa en recetas: ${t.enRecetas}', style: estiloSecundario),
          Text('Precio: ${t.precio}', style: estiloSecundario),
        ],
      ),
    );
  }
}
