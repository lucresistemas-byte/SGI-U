import 'package:flutter/material.dart';
import '../models/cambio_precio.dart';
import '../theme/app_colors.dart';
import '../utils/numeros.dart';

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
    return AlertDialog(
      key: const Key('cambios_precio_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(n == 1 ? 'Se actualizó 1 precio' : 'Se actualizaron $n precios',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Los precios ya están aplicados. Los carritos abiertos y las ventas anteriores no cambian.',
                  style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                  columns: const [
                    DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Precio anterior', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(
                        label: Text('Precio nuevo', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Ganancia', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
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
        ),
      ),
      actions: [
        ElevatedButton(
          key: const Key('cerrar_cambios_precio'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdePrincipal, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
