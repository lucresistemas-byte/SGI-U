import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_data_table.dart';
import 'app_dialog.dart';
import 'cargando_diferido.dart';
import 'tabla_ajustada.dart';

/// "Ver historial" de stock de un artículo (Productos y Materia Prima):
/// cada movimiento con su cantidad, el stock que quedó, el motivo y quién lo
/// hizo; filtrable por fechas y tipo.
class StockHistorialDialog extends StatefulWidget {
  final String codigo;
  final String nombre;
  final ApiService? apiService;

  const StockHistorialDialog({super.key, required this.codigo, required this.nombre, this.apiService});

  static Future<void> mostrar(BuildContext context, {required String codigo, required String nombre}) =>
      showDialog<void>(context: context, builder: (_) => StockHistorialDialog(codigo: codigo, nombre: nombre));

  @override
  State<StockHistorialDialog> createState() => _StockHistorialDialogState();
}

class _StockHistorialDialogState extends State<StockHistorialDialog> {
  late final ApiService _api = widget.apiService ?? ApiService();
  final _fecha = DateFormat('dd/MM/yyyy');
  final _fechaHora = DateFormat('dd/MM/yyyy HH:mm');
  late DateTime _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _hasta = DateTime.now();
  String? _tipo;
  List<MovimientoStock> _filas = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final filas = await _api.getMovimientosStock(widget.codigo, desde: _desde, hasta: _hasta, tipo: _tipo);
      if (mounted) setState(() => _filas = filas);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFecha({required bool desde}) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: desde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida == null) return;
    setState(() => desde ? _desde = elegida : _hasta = elegida);
    _buscar();
  }

  Widget _tabla() {
    if (_cargando) return const SizedBox(height: 200, child: CargandoDiferido());
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: AppColors.error));
    }
    if (_filas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
        child: Text('No hay movimientos en ese período.',
            style: AppTypography.texto.copyWith(color: AppColors.textoInactivo)),
      );
    }
    return AppDataTable(
      key: const Key('tabla_movimientos_stock'),
      separacionColumnas: AppSpacing.espacioGrande,
      colorEncabezado: AppColors.fondoApp,
      columnas: const [
        DataColumn(columnWidth: columnaAjustable, label: Text('Fecha')),
        DataColumn(columnWidth: columnaAjustable, label: Text('Tipo')),
        DataColumn(columnWidth: columnaAjustable, label: Text('Cantidad'), numeric: true),
        DataColumn(columnWidth: columnaAjustable, label: Text('Stock'), numeric: true),
        DataColumn(columnWidth: columnaFlexible, label: Text('Motivo')),
        DataColumn(columnWidth: columnaAjustable, label: Text('Usuario')),
      ],
      filas: [
        for (final m in _filas)
          DataRow(key: ValueKey('movimiento_${m.id}'), cells: [
            DataCell(Text(_fechaHora.format(m.fecha.toLocal()))),
            DataCell(Text(m.tipoDescripcion)),
            DataCell(Text(m.cantidadTexto,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: m.cantidad < 0 ? AppColors.textoSecundario : AppColors.exito))),
            DataCell(Text(m.stockResultanteTexto,
                key: Key('stock_resultante_${m.id}'),
                style: TextStyle(
                    color: m.stockResultante < 0 ? AppColors.error : null,
                    fontWeight: m.stockResultante < 0 ? FontWeight.bold : null))),
            DataCell(Text(m.motivo ?? '—', overflow: TextOverflow.ellipsis, maxLines: 2)),
            DataCell(Text(m.usuario ?? '—')),
          ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      key: const Key('stock_historial_dialog'),
      titulo: 'Historial de stock: ${widget.nombre} (${widget.codigo})',
      tamano: TamanoDialogo.grande,
      acciones: [
        AppButton.ghost(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.espacioMedio,
            runSpacing: AppSpacing.espacioMedio,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.secondary(
                key: const Key('stock_historial_desde'),
                icono: Icons.calendar_today,
                onPressed: () => _elegirFecha(desde: true),
                child: Text('Desde ${_fecha.format(_desde)}'),
              ),
              AppButton.secondary(
                key: const Key('stock_historial_hasta'),
                icono: Icons.calendar_today,
                onPressed: () => _elegirFecha(desde: false),
                child: Text('Hasta ${_fecha.format(_hasta)}'),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String?>(
                  key: const Key('stock_historial_tipo'),
                  initialValue: _tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(), isDense: true),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    for (final t in tiposMovimientoStock.entries)
                      DropdownMenuItem<String?>(value: t.key, child: Text(t.value)),
                  ],
                  onChanged: (t) {
                    setState(() => _tipo = t);
                    _buscar();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          _tabla(),
        ],
      ),
    );
  }
}
