import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/insumo.dart';
import '../models/paquete.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/numeros.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/paquete_form_dialog.dart';
import '../widgets/tabla_ajustada.dart';

/// Pestaña Paquetes de "Recetas y paquetes": cada paquete se arma con
/// insumos y un monto fijo; se vende en el POS como una línea (lo que va
/// adentro se cobra aparte).
class PaquetesScreen extends StatefulWidget {
  final ApiService? apiService;

  const PaquetesScreen({super.key, this.apiService});

  @override
  State<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends State<PaquetesScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  List<Paquete> _paquetes = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final paquetes = await _api.getPaquetes();
      if (mounted) setState(() => _paquetes = paquetes);
    } catch (e) {
      _avisar(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _avisar(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: error ? Colors.redAccent : AppColors.verdePrincipal,
    ));
  }

  Future<void> _abrir({Paquete? existente}) async {
    List<Insumo> insumos = const [];
    List<Categoria> categorias = const [];
    try {
      insumos = (await _api.getInsumos()).where((i) => i.tipo == 'INSUMO').toList();
      categorias = await _api.getCategorias();
    } catch (e) {
      _avisar(e.toString(), error: true);
      return;
    }
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaqueteFormDialog(existente: existente, insumos: insumos, categorias: categorias),
    );
    if (data == null) return;
    try {
      await _api.guardarPaquete(data, id: existente?.id);
      _avisar(existente == null ? 'Paquete creado correctamente' : 'Paquete actualizado correctamente');
      await _cargar();
    } catch (e) {
      _avisar(e.toString(), error: true);
    }
  }

  Future<void> _cambiarEstado(Paquete p) async {
    try {
      await _api.cambiarEstadoPaquete(p.id, activo: !p.activo);
      await _cargar();
    } catch (e) {
      _avisar(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paquetes',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    SizedBox(height: 4),
                    Text('Precio = costo del armado + monto fijo, redondeado hacia arriba a \$100',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton.icon(
                key: const Key('nuevo_paquete_button'),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo paquete'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrincipal, foregroundColor: Colors.white),
                onPressed: () => _abrir(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _tabla()),
        ],
      ),
    );
  }

  Widget _tabla() {
    if (_cargando) return const CargandoDiferido();
    if (_paquetes.isEmpty) {
      return const Center(
          child: Text('No hay paquetes. Cree uno con "Nuevo paquete".', style: TextStyle(color: Color(0xFF64748B))));
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TablaAjustada(
        tabla: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          columns: const [
            DataColumn(columnWidth: columnaAjustable, label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(columnWidth: columnaAjustable, label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(columnWidth: columnaFlexible, label: Text('Armado', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(columnWidth: columnaAjustable, label: Text('Costo armado', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(columnWidth: columnaAjustable, label: Text('Monto fijo', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(columnWidth: columnaAjustable, label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(columnWidth: columnaAjustable, label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            for (final p in _paquetes)
              DataRow(key: ValueKey('fila_paquete_${p.codigo}'), cells: [
                DataCell(Text(p.codigo, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(p.nombre),
                  if (!p.activo) ...[
                    const SizedBox(width: 8),
                    const Chip(label: Text('Inactivo'), visualDensity: VisualDensity.compact),
                  ],
                ])),
                DataCell(Text(p.armado.map((f) => f.articuloNombre ?? '').join(', '),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(Text(formatPesos(p.costoArmado))),
                DataCell(Text(formatPesos(p.montoFijo))),
                DataCell(Text(formatPesos(p.precioVenta),
                    key: Key('precio_paquete_${p.codigo}'), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatPesos(p.gananciaPesos), key: Key('ganancia_paquete_${p.codigo}'))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    key: Key('editar_paquete_${p.codigo}'),
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
                    onPressed: () => _abrir(existente: p),
                  ),
                  IconButton(
                    key: Key('estado_paquete_${p.codigo}'),
                    tooltip: p.activo ? 'Desactivar' : 'Reactivar',
                    icon: Icon(p.activo ? Icons.toggle_on : Icons.toggle_off,
                        color: p.activo ? AppColors.verdePrincipal : const Color(0xFF94A3B8)),
                    onPressed: () => _cambiarEstado(p),
                  ),
                ])),
              ]),
          ],
        ),
      ),
    );
  }
}
