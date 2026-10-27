import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/stock.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_dialog.dart';

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
    return AppDialog(
      titulo: 'Producir ${p.nombre}',
      tamano: TamanoDialogo.medio,
      acciones: [
        AppButton.ghost(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (hayFaltantes)
          AppButton.danger(
            key: const Key('producir_igual_button'),
            onPressed: _enviando ? null : () => _producir(confirmar: true),
            child: const Text('Producir igual'),
          )
        else
          AppButton.primary(
            key: const Key('producir_button'),
            onPressed: _enviando ? null : () => _producir(confirmar: false),
            child: const Text('Producir'),
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.esPaquete
                ? 'Suma stock del paquete y descuenta los insumos de su armado.'
                : 'Suma stock y descuenta los ingredientes de la receta según el rinde '
                    '(las preparaciones base se descuentan por sus ingredientes).',
            style: AppTypography.texto.copyWith(color: AppColors.textoInactivo),
          ),
          if (p.puedeProducir != null) ...[
            const SizedBox(height: AppSpacing.espacioChico),
            Text('Con el stock actual se pueden producir hasta ${p.puedeProducir}.',
                key: const Key('produccion_puede_producir')),
          ],
          const SizedBox(height: AppSpacing.espacioEstandar),
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
              const SizedBox(width: AppSpacing.espacioMedio),
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
            const SizedBox(height: AppSpacing.espacioMedio),
            Text(_error!,
                key: const Key('produccion_error'),
                style: const TextStyle(color: AppColors.error)),
          ],
          if (hayFaltantes) ...[
            const SizedBox(height: AppSpacing.espacioEstandar),
            Container(
              key: const Key('produccion_faltantes'),
              padding: const EdgeInsets.all(AppSpacing.espacioMedio),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppRadii.bordeChico,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No alcanza el stock. No se aplicó nada.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: AppSpacing.espacioChico),
                  for (final f in _faltantes)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.espacioMinimo),
                      child: Text('• ${f.mensaje}', key: Key('faltante_${f.codigo}')),
                    ),
                  const SizedBox(height: AppSpacing.espacioChico),
                  Text('Si produce igual, esos artículos quedan con stock negativo (en rojo).',
                      style: AppTypography.etiqueta.copyWith(color: AppColors.textoInactivo)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
