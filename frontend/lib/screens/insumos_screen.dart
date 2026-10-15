import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/insumos/insumos_bloc.dart';
import '../blocs/insumos/insumos_event.dart';
import '../blocs/insumos/insumos_state.dart';
import '../models/insumo.dart';
import '../models/unidad_stock.dart';
import '../utils/numeros.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/materia_prima_form_dialog.dart';
import '../widgets/stock_historial_dialog.dart';
import '../widgets/tabla_ajustada.dart';

class InsumosScreen extends StatefulWidget {
  final InsumosBloc? insumosBloc;
  final ApiService? apiService;

  const InsumosScreen({
    super.key,
    this.insumosBloc,
    this.apiService,
  });

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  late final InsumosBloc _bloc;
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _bloc = widget.insumosBloc ??
        InsumosBloc(apiService: widget.apiService ?? ApiService());
    _bloc.add(const CargarInsumos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.insumosBloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  Future<void> _mostrarDialogoInsumo({Insumo? insumoExistente}) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MateriaPrimaFormDialog(existente: insumoExistente),
    );
    if (data == null) return;
    if (insumoExistente == null) {
      _bloc.add(CrearInsumoEvent(data));
    } else {
      _bloc.add(ActualizarInsumoEvent(insumoExistente.id!, data));
    }
  }

  /// Unidades de ajuste: las de la familia, la presentación de compra y (reventa
  /// + materia prima) la unidad de venta.
  List<UnidadStock> _unidadesDeStock(Insumo insumo) => UnidadStock.opciones(
        insumo.familia,
        presentacionNombre: insumo.presentacionDescripcion,
        presentacionBase: insumo.presentacionEnBase,
        ventaNombre: insumo.ventaUnidadNombre,
        ventaBase: insumo.esReventaMateriaPrima && insumo.ventaUnidadContenido != insumo.presentacionEnBase
            ? insumo.ventaUnidadContenido
            : null,
      );

  /// "36 cajas · 50 g sueltos" (solo reventa + materia prima).
  String? _detalleUnidadesVenta(Insumo insumo) {
    if (!insumo.esReventaMateriaPrima || insumo.stockUnidadesVenta == null) return null;
    final suelto = insumo.stockSuelto ?? 0;
    return '${textoStock(insumo.stockUnidadesVenta!, insumo.ventaUnidadNombre ?? 'UNIDAD')}'
        '${suelto > 0 ? ' · ${textoEn(suelto, insumo.familia.base)} sueltos' : ''}';
  }

  /// Ajuste en una unidad de la familia, por presentación de compra ("llegó
  /// 1 bulto") o por unidad de venta ("3 cajas").
  void _mostrarDialogoAjusteStock(Insumo insumo) {
    final formKey = GlobalKey<FormState>();
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController(text: 'Ajuste manual de stock');
    final unidades = _unidadesDeStock(insumo);
    var unidad = insumo.unidad.codigo;
    // Tipo del movimiento; null = según el signo (compra si suma, ajuste si resta).
    String? tipoMovimiento;
    final detalle = _detalleUnidadesVenta(insumo);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Ajustar Stock: ${insumo.nombre}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock actual: ${textoEn(insumo.stockActual, insumo.unidad)}'
                    '${detalle != null ? ' ($detalle)' : ''}',
                    key: const Key('ajuste_stock_actual'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: const Key('ajuste_cantidad_input'),
                          controller: cantidadCtrl,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad (+ suma, - resta) *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final cant = parseDecimal(v);
                            if (cant == null || cant == 0) return 'Ingrese una cantidad distinta de 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          key: const Key('ajuste_unidad_dropdown'),
                          initialValue: unidad,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                          items: [
                            for (final u in unidades)
                              DropdownMenuItem(value: u.codigo, child: Text(u.nombre, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (u) {
                            if (u != null) setDialogState(() => unidad = u);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: const Key('ajuste_tipo_dropdown'),
                    initialValue: tipoMovimiento,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Según la cantidad (compra si suma, ajuste si resta)')),
                      DropdownMenuItem<String?>(value: 'COMPRA', child: Text('Compra')),
                      DropdownMenuItem<String?>(value: 'AJUSTE', child: Text('Ajuste')),
                      DropdownMenuItem<String?>(value: 'MERMA', child: Text('Merma (resta)')),
                    ],
                    onChanged: (t) => setDialogState(() => tipoMovimiento = t),
                    validator: (t) {
                      final cant = parseDecimal(cantidadCtrl.text) ?? 0;
                      if (t == 'COMPRA' && cant < 0) return 'Una compra suma: use una cantidad positiva';
                      if (t == 'MERMA' && cant > 0) return 'Una merma resta: use una cantidad negativa';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('ajuste_motivo_input'),
                    controller: motivoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: const Key('confirmar_ajuste_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdePrincipal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                _bloc.add(AjustarStockInsumoEvent(
                  id: insumo.id!,
                  cantidad: parseDecimal(cantidadCtrl.text)!,
                  unidad: unidad,
                  motivo: motivoCtrl.text.trim(),
                  tipo: tipoMovimiento,
                ));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Confirmar Ajuste'),
            ),
          ],
        ),
        );
      },
    );
  }

  /// Pide confirmación para desactivar y avisa en qué recetas activas se usa.
  Future<void> _confirmarDesactivar(Insumo insumo) async {
    List<String> recetas = const [];
    try {
      recetas = await _bloc.recetasActivasQueUsan(insumo.id!);
    } catch (_) {
      // Si no se pudieron consultar, se confirma igual sin la lista.
    }
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desactivar insumo'),
        content: Text(recetas.isEmpty
            ? '¿Desactivar "${insumo.nombre}"? Podrá reactivarlo cuando quiera.'
            : '"${insumo.nombre}" se usa en estas recetas activas: '
                '${recetas.join(', ')}.\n\nEsas recetas lo siguen teniendo para '
                'calcular el costo, pero no podrá agregarlo a recetas nuevas. '
                '¿Desactivarlo igual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmado == true && mounted) {
      _bloc.add(CambiarEstadoInsumoEvent(insumo.id!, activo: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        body: BlocConsumer<InsumosBloc, InsumosState>(
          listener: (context, state) {
            if (state is InsumoOperacionExitosa) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.mensaje),
                  backgroundColor: AppColors.verdePrincipal,
                ),
              );
            } else if (state is InsumosError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock de Materia Prima',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Administre insumos, costos unitarios y existencias para recetas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        key: const Key('nuevo_insumo_button'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Insumo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdePrincipal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _mostrarDialogoInsumo(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      key: const Key('buscar_insumo_input'),
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar insumo por nombre o código...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        _bloc.add(FiltrarInsumos(val));
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tabla de Insumos
                  Expanded(
                    child: _buildBody(state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(InsumosState state) {
    if (state is InsumosLoading && state is! InsumosLoaded) {
      return const CargandoDiferido();
    }

    List<Insumo> items = [];
    if (state is InsumosLoaded) {
      items = state.filteredInsumos;
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No hay insumos registrados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TablaAjustada(
          tabla: DataTable(
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: const [
              DataColumn(columnWidth: columnaAjustable, label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(columnWidth: columnaFlexible, label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(columnWidth: columnaAjustable, label: Text('Costo', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(columnWidth: columnaAjustable, label: Text('Unidad', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(columnWidth: columnaAjustable, label: Text('Stock Actual', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(columnWidth: columnaAjustable, label: Text('Stock Mínimo', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(columnWidth: columnaAjustable, label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.map((insumo) {
              final esBajoStock =
                  insumo.stockMinimo != null && insumo.stockActual <= insumo.stockMinimo!;
              // Negativo: una producción confirmada con faltantes.
              final negativo = insumo.stockActual < 0;
              // Los desactivados se ven atenuados y se pueden reactivar.
              final atenuado = insumo.activo
                  ? null
                  : const TextStyle(color: Color(0xFF94A3B8));
              return DataRow(
                key: ValueKey('fila_insumo_${insumo.codigo}'),
                cells: [
                  DataCell(Text(insumo.codigo,
                      style: (atenuado ?? const TextStyle()).copyWith(fontWeight: FontWeight.w600))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(insumo.nombre, style: atenuado)),
                      if (!insumo.activo) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Inactivo'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  )),
                  DataCell(Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_currencyFormat.format(insumo.costoUnitario)} / ${insumo.unidad.abreviatura}',
                          key: Key('costo_insumo_${insumo.codigo}'), style: atenuado),
                      // Reventa + materia prima: costo y precio de la unidad de venta.
                      if (insumo.esReventaMateriaPrima && insumo.precioVenta != null)
                        Text(
                          '${insumo.ventaUnidadNombre}: ${_currencyFormat.format(insumo.costoUnidadVenta ?? 0)}'
                          ' → ${_currencyFormat.format(insumo.precioVenta)}${insumo.precioManual ? ' (fijo)' : ''}',
                          key: Key('precio_venta_insumo_${insumo.codigo}'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                    ],
                  )),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        insumo.unidad.nombre,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              textoEn(insumo.stockActual, insumo.unidad).replaceAll('-', '−'),
                              key: Key('stock_insumo_${insumo.codigo}'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: negativo
                                    ? Colors.red.shade700
                                    : esBajoStock
                                        ? Colors.redAccent
                                        : Colors.black87,
                              ),
                            ),
                            if (negativo)
                              Text('Stock negativo',
                                  key: Key('stock_negativo_${insumo.codigo}'),
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                            // Cajas enteras (las que vende el POS) y lo suelto.
                            if (_detalleUnidadesVenta(insumo) != null)
                              Text(
                                _detalleUnidadesVenta(insumo)!,
                                key: Key('unidades_venta_insumo_${insumo.codigo}'),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                        if (esBajoStock) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message: 'Stock bajo el mínimo',
                            child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DataCell(Text(insumo.stockMinimo != null ? textoEn(insumo.stockMinimo!, insumo.unidad) : '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Ajustar Stock',
                          child: IconButton(
                            key: Key('ajustar_stock_${insumo.codigo}'),
                            icon: const Icon(Icons.tune, color: Color(0xFF0284C7)),
                            onPressed: () => _mostrarDialogoAjusteStock(insumo),
                          ),
                        ),
                        Tooltip(
                          message: 'Ver historial de stock',
                          child: IconButton(
                            key: Key('historial_stock_${insumo.codigo}'),
                            icon: const Icon(Icons.history, color: Color(0xFF64748B)),
                            onPressed: () =>
                                StockHistorialDialog.mostrar(context, codigo: insumo.codigo, nombre: insumo.nombre),
                          ),
                        ),
                        Tooltip(
                          message: 'Editar Insumo',
                          child: IconButton(
                            key: Key('editar_insumo_${insumo.codigo}'),
                            icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
                            onPressed: () => _mostrarDialogoInsumo(insumoExistente: insumo),
                          ),
                        ),
                        if (insumo.activo)
                          IconButton(
                            key: Key('desactivar_insumo_${insumo.codigo}'),
                            tooltip: 'Desactivar',
                            icon: const Icon(Icons.toggle_on, color: Color(0xFF13894E)),
                            onPressed: insumo.id == null ? null : () => _confirmarDesactivar(insumo),
                          )
                        else
                          IconButton(
                            key: Key('activar_insumo_${insumo.codigo}'),
                            tooltip: 'Reactivar',
                            icon: const Icon(Icons.toggle_off, color: Color(0xFF94A3B8)),
                            onPressed: insumo.id == null
                                ? null
                                : () => _bloc.add(CambiarEstadoInsumoEvent(insumo.id!, activo: true)),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
