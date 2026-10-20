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
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_data_table.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/materia_prima_form_dialog.dart';
import '../widgets/section_header.dart';
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
          builder: (context, setDialogState) => AppDialog(
          titulo: 'Ajustar Stock: ${insumo.nombre}',
          tamano: TamanoDialogo.medio,
          acciones: [
            AppButton.ghost(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            AppButton.primary(
              key: const Key('confirmar_ajuste_button'),
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
                  style: AppTypography.texto
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.espacioEstandar),
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
                        ),
                        validator: (v) {
                          final cant = parseDecimal(v);
                          if (cant == null || cant == 0) return 'Ingrese una cantidad distinta de 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.espacioChico),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: const Key('ajuste_unidad_dropdown'),
                        initialValue: unidad,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Unidad'),
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
                const SizedBox(height: AppSpacing.espacioMedio),
                DropdownButtonFormField<String?>(
                  key: const Key('ajuste_tipo_dropdown'),
                  initialValue: tipoMovimiento,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo'),
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
                const SizedBox(height: AppSpacing.espacioMedio),
                TextFormField(
                  key: const Key('ajuste_motivo_input'),
                  controller: motivoCtrl,
                  decoration: const InputDecoration(labelText: 'Motivo *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ],
            ),
          ),
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
      builder: (dialogContext) => AppDialog(
        titulo: 'Desactivar insumo',
        tamano: TamanoDialogo.chico,
        acciones: [
          AppButton.ghost(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
        child: Text(recetas.isEmpty
            ? '¿Desactivar "${insumo.nombre}"? Podrá reactivarlo cuando quiera.'
            : '"${insumo.nombre}" se usa en estas recetas activas: '
                '${recetas.join(', ')}.\n\nEsas recetas lo siguen teniendo para '
                'calcular el costo, pero no podrá agregarlo a recetas nuevas. '
                '¿Desactivarlo igual?'),
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
              AppSnackBar.exito(context, state.mensaje);
            } else if (state is InsumosError) {
              AppSnackBar.error(context, state.message);
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  SectionHeader(
                    titulo: 'Stock de Materia Prima',
                    subtitulo:
                        'Administre insumos, costos unitarios y existencias para recetas',
                    accion: AppButton.primary(
                      key: const Key('nuevo_insumo_button'),
                      icono: Icons.add,
                      onPressed: () => _mostrarDialogoInsumo(),
                      child: const Text('Nuevo Insumo'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.espacioGrande),

                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fondoSuperficie,
                      borderRadius: AppRadii.bordeTarjeta,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textoPrincipal.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.espacioEstandar),
                    child: TextField(
                      key: const Key('buscar_insumo_input'),
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar insumo por nombre o código...',
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.textoInactivo),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        _bloc.add(FiltrarInsumos(val));
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.espacioGrande),

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
      return const EmptyState(
        mensaje: 'No hay insumos registrados',
        icono: Icons.inventory_2_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [
          BoxShadow(
            color: AppColors.textoPrincipal.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.bordeTarjeta,
        child: AppDataTable(
          altoFilaMaximo: double.infinity,
          separacionColumnas: AppSpacing.espacioGrande,
          margenHorizontal: AppSpacing.espacioEstandar,
          colorEncabezado: AppColors.fondoApp,
          columnas: const [
            DataColumn(columnWidth: columnaAjustable, label: Text('Código')),
            DataColumn(columnWidth: columnaFlexible, label: Text('Nombre')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Costo')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Unidad')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Stock Actual')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Stock Mínimo')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Acciones')),
          ],
          filas: items.map((insumo) {
            final esBajoStock =
                insumo.stockMinimo != null && insumo.stockActual <= insumo.stockMinimo!;
            // Negativo: una producción confirmada con faltantes.
            final negativo = insumo.stockActual < 0;
            // Los desactivados se ven atenuados y se pueden reactivar.
            final atenuado = insumo.activo
                ? null
                : AppTypography.textoChico.copyWith(color: AppColors.textoInactivo);
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
                      const SizedBox(width: AppSpacing.espacioChico),
                      const EstadoChip(
                        etiqueta: 'Inactivo',
                        tono: TonoEstado.neutro,
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
                        style: AppTypography.etiqueta
                            .copyWith(color: AppColors.textoInactivo),
                      ),
                  ],
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.espacioChico,
                        vertical: AppSpacing.espacioMinimo),
                    decoration: const BoxDecoration(
                      color: AppColors.bordeSuave,
                      borderRadius: AppRadii.bordeChico,
                    ),
                    child: Text(
                      insumo.unidad.nombre,
                      style: AppTypography.etiqueta
                          .copyWith(fontWeight: FontWeight.w600),
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
                                  ? AppColors.error
                                  : esBajoStock
                                      ? AppColors.error
                                      : AppColors.textoPrincipal,
                            ),
                          ),
                          if (negativo)
                            Text('Stock negativo',
                                key: Key('stock_negativo_${insumo.codigo}'),
                                style: AppTypography.etiqueta
                                    .copyWith(color: AppColors.error)),
                          // Cajas enteras (las que vende el POS) y lo suelto.
                          if (_detalleUnidadesVenta(insumo) != null)
                            Text(
                              _detalleUnidadesVenta(insumo)!,
                              key: Key('unidades_venta_insumo_${insumo.codigo}'),
                              style: AppTypography.etiqueta
                                  .copyWith(color: AppColors.textoInactivo),
                            ),
                        ],
                      ),
                      if (esBajoStock) ...[
                        const SizedBox(width: AppSpacing.espacioMinimo),
                        const Tooltip(
                          message: 'Stock bajo el mínimo',
                          child: Icon(Icons.warning_amber_rounded, color: AppColors.alerta, size: 18),
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
                          icon: const Icon(Icons.tune, color: AppColors.info),
                          onPressed: () => _mostrarDialogoAjusteStock(insumo),
                        ),
                      ),
                      Tooltip(
                        message: 'Ver historial de stock',
                        child: IconButton(
                          key: Key('historial_stock_${insumo.codigo}'),
                          icon: const Icon(Icons.history, color: AppColors.textoInactivo),
                          onPressed: () =>
                              StockHistorialDialog.mostrar(context, codigo: insumo.codigo, nombre: insumo.nombre),
                        ),
                      ),
                      Tooltip(
                        message: 'Editar Insumo',
                        child: IconButton(
                          key: Key('editar_insumo_${insumo.codigo}'),
                          icon: const Icon(Icons.edit, color: AppColors.textoInactivo),
                          onPressed: () => _mostrarDialogoInsumo(insumoExistente: insumo),
                        ),
                      ),
                      if (insumo.activo)
                        IconButton(
                          key: Key('desactivar_insumo_${insumo.codigo}'),
                          tooltip: 'Desactivar',
                          icon: const Icon(Icons.toggle_on, color: AppColors.exito),
                          onPressed: insumo.id == null ? null : () => _confirmarDesactivar(insumo),
                        )
                      else
                        IconButton(
                          key: Key('activar_insumo_${insumo.codigo}'),
                          tooltip: 'Reactivar',
                          icon: const Icon(Icons.toggle_off, color: AppColors.textoInactivo),
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
    );
  }
}
