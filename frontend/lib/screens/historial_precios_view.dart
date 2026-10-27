import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/historial_precio.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../utils/numeros.dart';
import '../widgets/app_button.dart';
import '../widgets/app_data_table.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/tabla_ajustada.dart';

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
      padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.espacioMedio,
            runSpacing: AppSpacing.espacioMedio,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.secondary(
                key: const Key('historial_desde'),
                icono: Icons.calendar_today,
                onPressed: () => _elegirFecha(desde: true),
                child: Text('Desde ${_fecha.format(_desde)}'),
              ),
              AppButton.secondary(
                key: const Key('historial_hasta'),
                icono: Icons.calendar_today,
                onPressed: () => _elegirFecha(desde: false),
                child: Text('Hasta ${_fecha.format(_hasta)}'),
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
              AppButton.primary(
                key: const Key('historial_buscar'),
                icono: Icons.search,
                onPressed: _buscar,
                child: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          Expanded(child: _tabla()),
        ],
      ),
    );
  }

  Widget _tabla() {
    if (_cargando) return const CargandoDiferido();
    if (_error != null) {
      return ErrorState(mensaje: _error!, onReintentar: _buscar);
    }
    if (_filas.isEmpty) {
      return const EmptyState(
        mensaje: 'No hay cambios de precio en ese período.',
        icono: Icons.history,
      );
    }
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.fondoSuperficie, borderRadius: AppRadii.bordeTarjeta),
      child: AppDataTable(
        key: const Key('tabla_historial_precios'),
        separacionColumnas: AppSpacing.espacioGrande,
        margenHorizontal: AppSpacing.espacioEstandar,
        colorEncabezado: AppColors.fondoApp,
        columnas: const [
          DataColumn(columnWidth: columnaAjustable, label: Text('Fecha')),
          DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Producto')),
          DataColumn(columnWidth: columnaAjustable, label: Text('Costo')),
          DataColumn(columnWidth: columnaAjustable, label: Text('Precio')),
          DataColumn(columnWidth: columnaAjustable, label: Text('Modo')),
          DataColumn(columnWidth: columnaFlexible, label: Text('Causa')),
          DataColumn(columnWidth: columnaAjustable, label: Text('Usuario')),
        ],
        filas: [
          for (final h in _filas)
            DataRow(key: ValueKey('historial_${h.id}'), cells: [
              DataCell(Text(_fechaHora.format(h.fecha.toLocal()))),
              DataCell(Text('${h.nombre} (${h.codigo})', maxLines: 2, overflow: TextOverflow.ellipsis)),
              DataCell(Text('${_pesos(h.costoAnterior)} → ${_pesos(h.costoNuevo)}')),
              DataCell(Text(h.cambioPrecio ? '${_pesos(h.precioAnterior)} → ${_pesos(h.precioNuevo)}' : '—',
                  style: TextStyle(fontWeight: h.cambioPrecio ? FontWeight.bold : FontWeight.normal))),
              DataCell(Text(switch (h.modoPrecio) {
                'MANUAL' => 'A mano',
                'COSTO_MAS_FIJO' => 'Costo + fijo',
                _ => 'Margen',
              })),
              DataCell(Text(h.causa, overflow: TextOverflow.ellipsis, maxLines: 2)),
              DataCell(Text(h.usuario ?? '—')),
            ]),
        ],
      ),
    );
  }
}
