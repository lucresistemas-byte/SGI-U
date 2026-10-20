import 'package:flutter/material.dart';
import '../models/cambio_precio.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/numeros.dart';
import 'app_button.dart';
import 'app_dialog.dart';

/// Resumen de una propagación: "Se actualizaron N precios", con el precio
/// anterior, el nuevo y la ganancia por unidad en pesos.
class CambiosPrecioDialog extends StatelessWidget {
  final List<CambioPrecio> cambios;

  const CambiosPrecioDialog({super.key, required this.cambios});

  static Future<void> mostrar(BuildContext context, List<CambioPrecio> cambios) => showDialog<void>(
        context: context,
        builder: (_) => CambiosPrecioDialog(cambios: cambios),
      );

  @override
  Widget build(BuildContext context) {
    final n = cambios.length;
    return AppDialog(
      key: const Key('cambios_precio_dialog'),
      titulo: n == 1 ? 'Se actualizó 1 precio' : 'Se actualizaron $n precios',
      tamano: TamanoDialogo.grande,
      acciones: [
        AppButton.primary(
          key: const Key('cerrar_cambios_precio'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Los precios ya están aplicados. Los carritos abiertos y las ventas anteriores no cambian.',
              style: AppTypography.texto.copyWith(color: AppColors.textoInactivo)),
          const SizedBox(height: AppSpacing.espacioMedio),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: AppSpacing.espacioSeccion,
              headingRowColor: const WidgetStatePropertyAll(AppColors.fondoApp),
              columns: const [
                DataColumn(label: Text('Producto')),
                DataColumn(label: Text('Precio anterior'), numeric: true),
                DataColumn(label: Text('Precio nuevo'), numeric: true),
                DataColumn(label: Text('Ganancia'), numeric: true),
              ],
              rows: [
                for (final c in cambios)
                  DataRow(key: ValueKey('cambio_${c.codigo}'), cells: [
                    DataCell(Text('${c.nombre} (${c.codigo})')),
                    DataCell(Text(formatPesos(c.precioAnterior))),
                    DataCell(Text(formatPesos(c.precioNuevo),
                        key: Key('cambio_precio_nuevo_${c.codigo}'),
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(formatPesos(c.gananciaPesos), key: Key('cambio_ganancia_${c.codigo}'))),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
