import 'package:flutter/material.dart';
import '../../models/metodo_pago.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevations.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_button.dart';
import '../app_dialog.dart';
import '../app_snack_bar.dart';

/// Configuración > Métodos de pago: crear, renombrar, ordenar y
/// desactivar/reactivar. No se eliminan: uno desactivado no se ofrece, pero
/// los cobros que ya lo usaron lo siguen mostrando. "Efectivo" es fijo.
class MetodosPagoCard extends StatefulWidget {
  final ApiService apiService;

  const MetodosPagoCard({super.key, required this.apiService});

  @override
  State<MetodosPagoCard> createState() => _MetodosPagoCardState();
}

class _MetodosPagoCardState extends State<MetodosPagoCard> {
  List<MetodoPago> _metodos = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await widget.apiService.getMetodosPago(incluirInactivos: true);
      if (!mounted) return;
      setState(() {
        _metodos = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los métodos de pago.';
        _cargando = false;
      });
    }
  }

  Future<void> _ejecutar(Future<void> Function() accion, String? exito) async {
    try {
      await accion();
      if (!mounted) return;
      if (exito != null) {
        AppSnackBar.exito(context, exito);
      }
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    }
  }

  Future<String?> _pedirNombre({required String titulo, String inicial = ''}) {
    final ctrl = TextEditingController(text: inicial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AppDialog(
        titulo: titulo,
        tamano: TamanoDialogo.chico,
        acciones: [
          AppButton.ghost(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          AppButton.primary(
            key: const Key('metodo_pago_guardar_nombre'),
            onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
        child: TextField(
          key: const Key('metodo_pago_nombre_input'),
          controller: ctrl,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
      ),
    );
  }

  Future<void> _nuevo() async {
    final nombre = await _pedirNombre(titulo: 'Nuevo método de pago');
    if (nombre == null || nombre.isEmpty) return;
    await _ejecutar(() => widget.apiService.crearMetodoPago(nombre), 'Método de pago creado');
  }

  Future<void> _renombrar(MetodoPago m) async {
    final nombre = await _pedirNombre(titulo: 'Renombrar método de pago', inicial: m.nombre);
    if (nombre == null || nombre.isEmpty || nombre == m.nombre) return;
    await _ejecutar(() => widget.apiService.renombrarMetodoPago(m.id, nombre), 'Método de pago renombrado');
  }

  Future<void> _cambiarEstado(MetodoPago m) => _ejecutar(
        () => widget.apiService.cambiarEstadoMetodoPago(m.id, activo: !m.activo),
        m.activo ? 'Método de pago desactivado' : 'Método de pago reactivado',
      );

  Future<void> _mover(int desde, int hasta) {
    final ids = _metodos.map((m) => m.id).toList();
    final id = ids.removeAt(desde);
    ids.insert(hasta, id);
    return _ejecutar(() => widget.apiService.reordenarMetodosPago(ids), null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('config_metodos_pago'),
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
            Row(
              children: [
                Expanded(
                  child: Text('Métodos de pago',
                      style: AppTypography.texto.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoPrincipal)),
                ),
                TextButton.icon(
                  key: const Key('metodo_pago_nuevo_btn'),
                  onPressed: _nuevo,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo método'),
                ),
              ],
            ),
            Text(
              'Se ofrecen en este orden en el punto de venta, Pedidos y Movimientos. '
              'No se eliminan: se desactivan. Efectivo es fijo.',
              style: AppTypography.etiqueta
                  .copyWith(color: AppColors.textoInactivo),
            ),
            const SizedBox(height: AppSpacing.espacioChico),
            if (_cargando)
              const Padding(
                  padding: EdgeInsets.all(AppSpacing.espacioMedio),
                  child: LinearProgressIndicator())
            else if (_error != null)
              Text(_error!,
                  style: AppTypography.textoChico
                      .copyWith(color: AppColors.error))
            else
              for (var i = 0; i < _metodos.length; i++) _fila(i, _metodos[i]),
          ],
        ),
      ),
    );
  }

  Widget _fila(int i, MetodoPago m) => ListTile(
        key: Key('metodo_pago_${m.id}'),
        contentPadding: EdgeInsets.zero,
        title: Text(m.nombre,
            style: m.activo
                ? null
                : AppTypography.texto.copyWith(color: AppColors.textoInactivo)),
        subtitle: m.fijo
            ? const Text('Fijo: no se renombra ni se desactiva')
            : (m.activo ? null : const Text('Inactivo')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('metodo_pago_subir_${m.id}'),
              tooltip: 'Subir',
              icon: const Icon(Icons.arrow_upward),
              onPressed: i == 0 ? null : () => _mover(i, i - 1),
            ),
            IconButton(
              key: Key('metodo_pago_bajar_${m.id}'),
              tooltip: 'Bajar',
              icon: const Icon(Icons.arrow_downward),
              onPressed: i == _metodos.length - 1 ? null : () => _mover(i, i + 1),
            ),
            if (!m.fijo) ...[
              IconButton(
                key: Key('metodo_pago_renombrar_${m.id}'),
                tooltip: 'Renombrar',
                icon: const Icon(Icons.edit),
                onPressed: () => _renombrar(m),
              ),
              IconButton(
                key: Key('metodo_pago_estado_${m.id}'),
                tooltip: m.activo ? 'Desactivar' : 'Reactivar',
                icon: Icon(m.activo ? Icons.toggle_on : Icons.toggle_off,
                    color: m.activo
                        ? AppColors.estadoActivo
                        : AppColors.textoInactivo),
                onPressed: () => _cambiarEstado(m),
              ),
            ],
          ],
        ),
      );
}
