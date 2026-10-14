import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/historial_precio.dart';
import '../services/api_service.dart';
import '../utils/numeros.dart';
import '../widgets/cargando_diferido.dart';

/// Pestaña "Historial de precios" de Productos: cada cambio de costo o
/// precio, con su causa, filtrable por fechas y por producto (código).
class HistorialPreciosView extends StatefulWidget {
  final ApiService? apiService;

  const HistorialPreciosView({super.key, this.apiService});

  @override
  State<HistorialPreciosView> createState() => _HistorialPreciosViewState();
}

class _HistorialPreciosViewState extends State<HistorialPreciosView> {
  late final ApiService _api = widget.apiService ?? ApiService();
  final _codigoCtrl = TextEditingController();
  final _fecha = DateFormat('dd/MM/yyyy');
  final _fechaHora = DateFormat('dd/MM/yyyy HH:mm');
  late DateTime _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _hasta = DateTime.now();
  List<HistorialPrecio> _filas = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final filas = await _api.getHistorialPrecios(
          desde: _desde, hasta: _hasta, codigo: _codigoCtrl.text.trim().toUpperCase());
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

  String _pesos(double? v) => v == null ? '—' : formatPesos(v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('historial_desde'),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('Desde ${_fecha.format(_desde)}'),
                onPressed: () => _elegirFecha(desde: true),
              ),
              OutlinedButton.icon(
                key: const Key('historial_hasta'),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('Hasta ${_fecha.format(_hasta)}'),
                onPressed: () => _elegirFecha(desde: false),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('historial_codigo'),
                  controller: _codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código de producto',
                    hintText: 'Ej: ELA-0002',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('historial_buscar'),
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                onPressed: _buscar,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _tabla()),
        ],
      ),
    );
  }

  Widget _tabla() {
    if (_cargando) return const CargandoDiferido();
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_filas.isEmpty) {
      return const Center(
          child: Text('No hay cambios de precio en ese período.', style: TextStyle(color: Color(0xFF64748B))));
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            key: const Key('tabla_historial_precios'),
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: const [
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Costo', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Modo', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Causa', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              for (final h in _filas)
                DataRow(key: ValueKey('historial_${h.id}'), cells: [
                  DataCell(Text(_fechaHora.format(h.fecha.toLocal()))),
                  DataCell(Text('${h.nombre} (${h.codigo})')),
                  DataCell(Text('${_pesos(h.costoAnterior)} → ${_pesos(h.costoNuevo)}')),
                  DataCell(Text(h.cambioPrecio ? '${_pesos(h.precioAnterior)} → ${_pesos(h.precioNuevo)}' : '—',
                      style: TextStyle(fontWeight: h.cambioPrecio ? FontWeight.bold : FontWeight.normal))),
                  DataCell(Text(switch (h.modoPrecio) {
                    'MANUAL' => 'A mano',
                    'COSTO_MAS_FIJO' => 'Costo + fijo',
                    _ => 'Margen',
                  })),
                  DataCell(SizedBox(width: 320, child: Text(h.causa, overflow: TextOverflow.ellipsis, maxLines: 2))),
                  DataCell(Text(h.usuario ?? '—')),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
