import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/stock.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Producir (cargar stock de) un elaborado o un paquete: descuenta sus
/// ingredientes o insumos. En dos pasos: si algo no alcanza, muestra qué
/// falta y no aplica nada; si Sandra confirma, produce igual (el stock queda
/// negativo). Devuelve el resultado con `Navigator.pop` (null si se canceló).
class ProduccionDialog extends StatefulWidget {
  final Product producto;
  final ApiService? apiService;

  const ProduccionDialog({super.key, required this.producto, this.apiService});

  @override
  State<ProduccionDialog> createState() => _ProduccionDialogState();
}

class _ProduccionDialogState extends State<ProduccionDialog> {
  late final ApiService _api = widget.apiService ?? ApiService();
  final _cantidad = TextEditingController(text: '1');
  final _motivo = TextEditingController();
  List<Faltante> _faltantes = const [];
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _cantidad.dispose();
    _motivo.dispose();
    super.dispose();
  }

  int? get _cantidadValida {
    final c = int.tryParse(_cantidad.text.trim());
    return c != null && c > 0 ? c : null;
  }

  Future<void> _producir({required bool confirmar}) async {
    final cantidad = _cantidadValida;
    if (cantidad == null) {
      setState(() => _error = 'Ingrese una cantidad entera mayor a 0.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final resultado = await _api.producir(widget.producto.codigo,
          cantidad: cantidad, confirmarFaltantes: confirmar, motivo: _motivo.text.trim());
      if (mounted) Navigator.of(context).pop(resultado);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.codigo == 'FALTAN_COMPONENTES') {
          _faltantes = Faltante.deDatos(e.datos);
        } else {
          _error = e.mensaje;
        }
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final hayFaltantes = _faltantes.isNotEmpty;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Producir ${p.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.esPaquete
                  ? 'Suma stock del paquete y descuenta los insumos de su armado.'
                  : 'Suma stock y descuenta los ingredientes de la receta según el rinde '
                      '(las preparaciones base se descuentan por sus ingredientes).',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            if (p.puedeProducir != null) ...[
              const SizedBox(height: 8),
              Text('Con el stock actual se pueden producir hasta ${p.puedeProducir}.',
                  key: const Key('produccion_puede_producir')),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    key: const Key('produccion_cantidad_input'),
                    controller: _cantidad,
                    enabled: !hayFaltantes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('produccion_motivo_input'),
                    controller: _motivo,
                    enabled: !hayFaltantes,
                    decoration: const InputDecoration(
                        labelText: 'Detalle (opcional)', hintText: 'Ej: Tanda del sábado', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, key: const Key('produccion_error'), style: const TextStyle(color: Colors.redAccent)),
            ],
            if (hayFaltantes) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('produccion_faltantes'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No alcanza el stock. No se aplicó nada.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                    const SizedBox(height: 6),
                    for (final f in _faltantes)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• ${f.mensaje}', key: Key('faltante_${f.codigo}')),
                      ),
                    const SizedBox(height: 8),
                    const Text('Si produce igual, esos artículos quedan con stock negativo (en rojo).',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _enviando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        if (hayFaltantes)
          ElevatedButton(
            key: const Key('producir_igual_button'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white),
            onPressed: _enviando ? null : () => _producir(confirmar: true),
            child: const Text('Producir igual'),
          )
        else
          ElevatedButton(
            key: const Key('producir_button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdePrincipal, foregroundColor: Colors.white),
            onPressed: _enviando ? null : () => _producir(confirmar: false),
            child: const Text('Producir'),
          ),
      ],
    );
  }
}
