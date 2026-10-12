import 'package:flutter/material.dart';
import '../../models/tipo_articulo.dart';

/// Configuración > Tipos de producto: los 6 tipos del sistema, solo lectura.
class TiposProductoCard extends StatelessWidget {
  const TiposProductoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('config_tipos_producto'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipos de producto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Los tipos son fijos del sistema y deciden cómo se comporta cada producto. '
              'Las categorías son sus propias etiquetas para filtrar y para los reportes.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            for (final t in TipoArticuloInfo.todos) _tipo(t),
          ],
        ),
      ),
    );
  }

  Widget _tipo(TipoArticuloInfo t) {
    return Padding(
      key: Key('tipo_info_${t.codigo}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(t.queEs),
          Text('Se vende en el punto de venta: ${t.seVende}',
              style: const TextStyle(color: Color(0xFF475569))),
          Text('Se usa en recetas: ${t.enRecetas}',
              style: const TextStyle(color: Color(0xFF475569))),
          Text('Precio: ${t.precio}', style: const TextStyle(color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
