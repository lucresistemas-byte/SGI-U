import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/insumo.dart';
import '../models/paquete.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../utils/numeros.dart';
import '../widgets/app_button.dart';
import '../widgets/app_data_table.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/paquete_form_dialog.dart';
import '../widgets/section_header.dart';
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
    if (error) {
      AppSnackBar.error(context, mensaje);
    } else {
      AppSnackBar.exito(context, mensaje);
    }
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
      padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            titulo: 'Paquetes',
            subtitulo:
                'Precio = costo del armado + monto fijo, redondeado hacia arriba a \$100',
            accion: AppButton.primary(
              key: const Key('nuevo_paquete_button'),
              icono: Icons.add,
              onPressed: () => _abrir(),
              child: const Text('Nuevo paquete'),
            ),
          ),
          const SizedBox(height: AppSpacing.espacioGrande),
          Expanded(child: _tabla()),
        ],
      ),
    );
  }

  Widget _tabla() {
    if (_cargando) return const CargandoDiferido();
    if (_paquetes.isEmpty) {
      return const EmptyState(
        mensaje: 'No hay paquetes. Cree uno con "Nuevo paquete".',
        icono: Icons.card_giftcard,
      );
    }
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.fondoSuperficie, borderRadius: AppRadii.bordeTarjeta),
      child: AppDataTable(
        separacionColumnas: AppSpacing.espacioGrande,
        margenHorizontal: AppSpacing.espacioEstandar,
        colorEncabezado: AppColors.fondoApp,
        columnas: const [
          DataColumn(columnWidth: columnaAjustable, label: Text('Código')),
          DataColumn(columnWidth: columnaAjustable, label: Text('Nombre')),
          DataColumn(columnWidth: columnaFlexible, label: Text('Armado')),
          DataColumn(columnWidth: columnaAjustable, label: Text('Costo armado'), numeric: true),
          DataColumn(columnWidth: columnaAjustable, label: Text('Monto fijo'), numeric: true),
          DataColumn(columnWidth: columnaAjustable, label: Text('Precio'), numeric: true),
          DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia'), numeric: true),
          DataColumn(columnWidth: columnaAjustable, label: Text('Acciones')),
        ],
        filas: [
          for (final p in _paquetes)
            DataRow(key: ValueKey('fila_paquete_${p.codigo}'), cells: [
              DataCell(Text(p.codigo,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p.nombre),
                if (!p.activo) ...[
                  const SizedBox(width: AppSpacing.espacioChico),
                  const EstadoChip(etiqueta: 'Inactivo', tono: TonoEstado.neutro),
                ],
              ])),
              DataCell(Text(p.armado.map((f) => f.articuloNombre ?? '').join(', '),
                  style: const TextStyle(color: AppColors.textoInactivo))),
              DataCell(Text(formatPesos(p.costoArmado))),
              DataCell(Text(formatPesos(p.montoFijo))),
              DataCell(Text(formatPesos(p.precioVenta),
                  key: Key('precio_paquete_${p.codigo}'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(formatPesos(p.gananciaPesos), key: Key('ganancia_paquete_${p.codigo}'))),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  key: Key('editar_paquete_${p.codigo}'),
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit, color: AppColors.textoInactivo),
                  onPressed: () => _abrir(existente: p),
                ),
                IconButton(
                  key: Key('estado_paquete_${p.codigo}'),
                  tooltip: p.activo ? 'Desactivar' : 'Reactivar',
                  icon: Icon(p.activo ? Icons.toggle_on : Icons.toggle_off,
                      color: p.activo ? AppColors.marca : AppColors.textoInactivo),
                  onPressed: () => _cambiarEstado(p),
                ),
              ])),
            ]),
        ],
      ),
    );
  }
}
