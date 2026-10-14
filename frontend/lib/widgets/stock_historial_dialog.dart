import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../services/api_service.dart';
import 'cargando_diferido.dart';

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
    if (_error != null) return Text(_error!, style: const TextStyle(color: Colors.redAccent));
    if (_filas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No hay movimientos en ese período.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('tabla_movimientos_stock'),
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
        columns: const [
          DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Motivo', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: [
          for (final m in _filas)
            DataRow(key: ValueKey('movimiento_${m.id}'), cells: [
              DataCell(Text(_fechaHora.format(m.fecha.toLocal()))),
              DataCell(Text(m.tipoDescripcion)),
              DataCell(Text(m.cantidadTexto,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: m.cantidad < 0 ? const Color(0xFF475569) : const Color(0xFF15803D)))),
              DataCell(Text(m.stockResultanteTexto,
                  key: Key('stock_resultante_${m.id}'),
                  style: TextStyle(
                      color: m.stockResultante < 0 ? Colors.red.shade700 : null,
                      fontWeight: m.stockResultante < 0 ? FontWeight.bold : null))),
              DataCell(SizedBox(width: 260, child: Text(m.motivo ?? '—', overflow: TextOverflow.ellipsis, maxLines: 2))),
              DataCell(Text(m.usuario ?? '—')),
            ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('stock_historial_dialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Historial de stock: ${widget.nombre} (${widget.codigo})',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 860,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('stock_historial_desde'),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Desde ${_fecha.format(_desde)}'),
                    onPressed: () => _elegirFecha(desde: true),
                  ),
                  OutlinedButton.icon(
                    key: const Key('stock_historial_hasta'),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Hasta ${_fecha.format(_hasta)}'),
                    onPressed: () => _elegirFecha(desde: false),
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
              const SizedBox(height: 16),
              _tabla(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
