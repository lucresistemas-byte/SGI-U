import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/recetas/recetas_bloc.dart';
import '../blocs/recetas/recetas_event.dart';
import '../blocs/recetas/recetas_state.dart';
import '../models/insumo.dart';
import '../models/receta_detalle.dart';
import '../models/unidad_medida.dart';
import '../utils/numeros.dart';
import '../models/receta.dart';
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
import '../widgets/section_header.dart';
import '../widgets/tabla_ajustada.dart';

class RecetasScreen extends StatefulWidget {
  final RecetasBloc? recetasBloc;
  final ApiService? apiService;
  final bool initialBuildingMode;

  const RecetasScreen({
    super.key,
    this.recetasBloc,
    this.apiService,
    this.initialBuildingMode = false,
  });

  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> {
  late final RecetasBloc _bloc;
  late bool _isBuilding;
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _costosAdicCtrl = TextEditingController(text: '0.00');
  final _rindeCtrl = TextEditingController();
  final _rindeUnidadCtrl = TextEditingController(text: 'porciones');

  @override
  void initState() {
    super.initState();
    _isBuilding = widget.initialBuildingMode;
    _bloc = widget.recetasBloc ??
        RecetasBloc(apiService: widget.apiService ?? ApiService());
    _bloc.add(const CargarRecetas());
    _bloc.add(const CargarDatosAuxiliaresReceta());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _costosAdicCtrl.dispose();
    _rindeCtrl.dispose();
    _rindeUnidadCtrl.dispose();
    if (widget.recetasBloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _iniciarNuevaReceta() {
    _nombreCtrl.clear();
    _descripcionCtrl.clear();
    _costosAdicCtrl.text = '0.00';
    _rindeCtrl.clear();
    _rindeUnidadCtrl.text = 'porciones';
    _bloc.add(const IniciarNuevaReceta());
    setState(() {
      _isBuilding = true;
    });
  }

  void _editarReceta(Receta receta) {
    _nombreCtrl.text = receta.nombre;
    _descripcionCtrl.text = receta.descripcion ?? '';
    _costosAdicCtrl.text = receta.costosAdicionales.toStringAsFixed(2);
    _rindeCtrl.text = formatDecimal(receta.rinde);
    _rindeUnidadCtrl.text = receta.rindeUnidad;
    _bloc.add(EditarReceta(receta));
    setState(() {
      _isBuilding = true;
    });
  }

  /// Producto de la receta. Al crear: uno nuevo (la receta crea el
  /// elaborado) o un elaborado existente sin receta. Al editar, fijo.
  Widget _buildSelectorProducto(RecetasState state) {
    if (state.editingRecetaId != null) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Producto elaborado',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('${state.selectedProductoNombre} (${state.selectedProductoCodigo})',
                  key: const Key('producto_receta_fijo')),
            ),
            if (!state.productoEditadoActivo)
              const EstadoChip(
                key: Key('producto_inactivo_armador'),
                etiqueta: 'Producto inactivo',
                tono: TonoEstado.neutro,
              ),
          ],
        ),
      );
    }

    final elaborados = state.elaboradosSinReceta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          key: const Key('modo_producto_receta'),
          segments: const [
            ButtonSegment(value: true, label: Text('Producto nuevo'), icon: Icon(Icons.add)),
            ButtonSegment(value: false, label: Text('Producto existente'), icon: Icon(Icons.inventory_2)),
          ],
          selected: {state.usarProductoNuevo},
          onSelectionChanged: (v) =>
              _bloc.add(CambiarModoProductoReceta(productoNuevo: v.first)),
        ),
        const SizedBox(height: 12),
        if (state.usarProductoNuevo) ..._camposProductoNuevo(state)
        else if (elaborados.isEmpty)
          Text(
            'No hay productos elaborados sin receta. Cree uno nuevo.',
            key: const Key('sin_elaborados_sin_receta'),
            style: AppTypography.texto.copyWith(
                color: AppColors.textoInactivo, fontStyle: FontStyle.italic),
          )
        else
          DropdownButtonFormField<String>(
            key: const Key('selector_producto_receta'),
            isExpanded: true,
            initialValue: elaborados.any((p) => p.codigo == state.selectedProductoCodigo)
                ? state.selectedProductoCodigo
                : null,
            decoration: const InputDecoration(
              labelText: 'Producto elaborado *',
              border: OutlineInputBorder(),
            ),
            items: elaborados
                .map((p) => DropdownMenuItem<String>(
                      value: p.codigo,
                      child: Text('${p.nombre} (${p.codigo})'),
                    ))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              final p = elaborados.firstWhere((item) => item.codigo == val);
              _bloc.add(CambiarProductoReceta(codigo: p.codigo, nombre: p.nombre));
            },
          ),
      ],
    );
  }

  List<Widget> _camposProductoNuevo(RecetasState state) => [
        TextFormField(
          key: const Key('nuevo_producto_nombre'),
          initialValue: state.nuevoProductoNombre,
          decoration: const InputDecoration(
            labelText: 'Nombre del producto *',
            hintText: 'Ej: Tarta de coco',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _bloc.add(ActualizarProductoNuevoReceta(nombre: v)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // El código (ELA-0001, ...) lo genera el sistema al guardar.
            SizedBox(
              width: 140,
              child: TextFormField(
                key: const Key('nuevo_producto_porcentaje'),
                initialValue: state.nuevoProductoPorcentaje?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '% ganancia',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _bloc.add(ActualizarProductoNuevoReceta(
                    porcentajeGanancia: double.tryParse(v.replaceAll(',', '.')) ?? 0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              // La clave cambia con la categoría elegida para que el
              // desplegable muestre la que se acaba de crear con "+".
              child: KeyedSubtree(
                key: ValueKey('categoria_elegida_${state.nuevoProductoCategoriaId}'),
                child: DropdownButtonFormField<int>(
                  key: const Key('nuevo_producto_categoria'),
                  isExpanded: true,
                  initialValue: state.availableCategorias
                          .any((c) => c.id == state.nuevoProductoCategoriaId)
                      ? state.nuevoProductoCategoriaId
                      : null,
                  hint: const Text('Elegir categoría'),
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                  ),
                  items: state.availableCategorias
                      .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _bloc.add(ActualizarProductoNuevoReceta(categoriaId: v));
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('nueva_categoria_button'),
              tooltip: 'Nueva categoría',
              icon: const Icon(Icons.add),
              onPressed: _crearCategoria,
            ),
          ],
        ),
        CheckboxListTile(
          key: const Key('nuevo_producto_preparacion_base'),
          contentPadding: EdgeInsets.zero,
          value: state.nuevoProductoPreparacionBase,
          onChanged: (v) =>
              _bloc.add(ActualizarProductoNuevoReceta(preparacionBase: v ?? false)),
          title: const Text('Preparación base (no se vende)'),
          subtitle: const Text('Ej.: ganache. No aparece en el punto de venta.'),
        ),
      ];

  /// Pide el nombre de una categoría nueva; el bloc la crea y la elige.
  Future<void> _crearCategoria() async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => const _NuevaCategoriaDialog(),
    );
    if (nombre != null && nombre.trim().isNotEmpty) {
      _bloc.add(CrearCategoriaReceta(nombre));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        body: BlocConsumer<RecetasBloc, RecetasState>(
          bloc: _bloc,
          // Solo cuando aparece un mensaje nuevo: si no, cada estado posterior
          // (p. ej. la recarga de la lista) lo volvía a mostrar.
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              // En el armador, el único éxito posible es guardar: recién ahí
              // se vuelve a la lista.
              if (_isBuilding) {
                setState(() => _isBuilding = false);
              }
              AppSnackBar.exito(context, state.successMessage!);
            }
            if (state.errorMessage != null) {
              AppSnackBar.error(context, state.errorMessage!);
            }
            if (state.successMessage != null || state.errorMessage != null) {
              _bloc.add(const LimpiarMensajesRecetas());
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isBuilding
                  ? _buildRecipeBuilder(context, state)
                  : _buildRecipeList(context, state),
            );
          },
        ),
      ),
    );
  }

  // --- LIST VIEW ---
  Widget _buildRecipeList(BuildContext context, RecetasState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          titulo: 'Recetas de Fabricación',
          subtitulo: 'Defina insumos y costos para productos elaborados',
          accion: AppButton.primary(
            key: const Key('nueva_receta_button'),
            icono: Icons.add,
            onPressed: _iniciarNuevaReceta,
            child: const Text('Nueva Receta'),
          ),
        ),
        const SizedBox(height: AppSpacing.espacioSeccion),
        if (state.isLoading && state.recetas.isEmpty)
          const Expanded(child: CargandoDiferido())
        else if (state.recetas.isEmpty)
          const Expanded(
            child: EmptyState(
              mensaje: 'No hay recetas registradas',
              icono: Icons.menu_book_outlined,
            ),
          )
        else
          Expanded(
            child: Container(
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
                  separacionColumnas: AppSpacing.espacioGrande,
                  margenHorizontal: AppSpacing.espacioEstandar,
                  colorEncabezado: AppColors.fondoApp,
                  columnas: const [
                    DataColumn(columnWidth: columnaAjustable, label: Text('Producto Elaborado')),
                    DataColumn(columnWidth: columnaFlexible, label: Text('Nombre Receta')),
                    DataColumn(columnWidth: columnaAjustable, label: Text('Insumos')),
                    DataColumn(columnWidth: columnaAjustable, label: Text('Costos Adic.')),
                    DataColumn(columnWidth: columnaAjustable, label: Text('Costo Total')),
                    DataColumn(columnWidth: columnaAjustable, label: Text('Acciones')),
                  ],
                  filas: state.recetas.map((r) {
                      // La receta siempre se ve; si su producto está
                      // desactivado, se marca (no se vende en el POS).
                      final atenuado = r.productoActivo
                          ? null
                          : const TextStyle(color: AppColors.textoInactivo);
                      return DataRow(
                        key: ValueKey('fila_receta_${r.id}'),
                        cells: [
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(r.espProductoNombre ?? r.espProductoCodigo,
                                  style: (atenuado ?? const TextStyle())
                                      .copyWith(fontWeight: FontWeight.w600)),
                              if (!r.productoActivo) ...[
                                const SizedBox(width: AppSpacing.espacioChico),
                                const EstadoChip(
                                  key: Key('producto_inactivo_chip'),
                                  etiqueta: 'Producto inactivo',
                                  tono: TonoEstado.neutro,
                                ),
                              ],
                            ],
                          )),
                          DataCell(Text(r.nombre, style: atenuado)),
                          DataCell(Text('${r.detalles.length} insumos', style: atenuado)),
                          DataCell(Text(_currencyFormat.format(r.costosAdicionales), style: atenuado)),
                          DataCell(Text(_currencyFormat.format(r.costoTotal),
                              style: atenuado ??
                                  const TextStyle(fontWeight: FontWeight.bold, color: AppColors.exito))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('editar_receta_${r.id}'),
                                  icon: const Icon(Icons.edit, color: AppColors.textoInactivo),
                                  onPressed: () => _editarReceta(r),
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
          ),
      ],
    );
  }

  /// "porciones" → "porción"; "unidades" → "unidad"; otros, como están.
  static String _singular(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return 'unidad';
    if (t.endsWith('ones')) return '${t.substring(0, t.length - 4)}ón';
    if (t.endsWith('des')) return t.substring(0, t.length - 2);
    if (t.endsWith('s')) return t.substring(0, t.length - 1);
    return t;
  }

  /// Preparación base: no tiene precio; muestra su costo por unidad del
  /// rinde (el que usan las recetas que la llevan).
  List<Widget> _resumenPreparacionBase(RecetasState state) {
    final unidad = UnidadMedida.deCodigo(state.rindeUnidadMedida) ?? UnidadMedida.gramo;
    final rinde = state.rinde;
    if (rinde == null || rinde <= 0) {
      return [_dato('Costo por ${unidad.abreviatura}', '—', const Key('costo_por_unidad_receta'), detalle: 'Falta el rinde')];
    }
    final porBase = state.costoTotal / unidad.aBase(rinde);
    final grande = unidad.familia!.unidades.last;
    return [
      _dato('Costo por ${grande.abreviatura}', formatPesos(porBase * grande.factor), const Key('costo_por_unidad_receta'),
          detalle: 'Rinde ${formatDecimal(rinde)} ${unidad.abreviatura} · ${formatPesos(porBase, decimales: 4)} por '
              '${unidad.familia!.base.abreviatura}'),
      _dato('Preparación base', 'No se vende', const Key('precio_resultante_receta'),
          detalle: 'Se usa como ingrediente de otras recetas'),
    ];
  }

  Widget _dato(String titulo, String valor, Key key, {String? detalle}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: AppTypography.etiqueta.copyWith(
                  color: AppColors.exito, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.espacioMinimo),
          Text(valor,
              key: key,
              style: AppTypography.numeroKpi.copyWith(color: AppColors.exito)),
          if (detalle != null)
            Text(detalle, style: AppTypography.etiqueta.copyWith(color: AppColors.exito)),
        ],
      );

  /// Unidad de la fila: desplegable con las unidades de la familia del insumo
  /// (sin insumo elegido o si el insumo ya no está disponible, solo texto).
  Widget _unidadDeFila(RecetasState state, RecetaDetalle detalle, int index) {
    final unidad = UnidadMedida.deCodigo(detalle.unidadMedida);
    Insumo? insumo;
    for (final i in state.availableInsumos) {
      if (i.id == detalle.articuloId) insumo = i;
    }
    if (detalle.sinInsumo || insumo == null || unidad == null) {
      return SizedBox(
        width: 110,
        child: Text(unidad?.nombre ?? '—', key: Key('unidad_insumo_fila_$index'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    // Se recrea al cambiar insumo o unidad (initialValue se lee una sola vez).
    return SizedBox(
      key: ValueKey('unidad_${detalle.articuloId}_${unidad.codigo}'),
      width: 120,
      child: DropdownButtonFormField<UnidadMedida>(
        key: Key('unidad_insumo_fila_$index'),
        initialValue: unidad,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Unidad',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [for (final u in insumo.familia.unidades) DropdownMenuItem(value: u, child: Text(u.nombre))],
        onChanged: (u) {
          if (u != null) _bloc.add(CambiarUnidadFila(index: index, unidad: u));
        },
      ),
    );
  }

  // --- BUILDER VIEW ---
  Widget _buildRecipeBuilder(BuildContext context, RecetasState state) {
    // El encabezado (título y "Guardar receta") queda fijo; solo se
    // desplaza el contenido del armador.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('volver_lista_button'),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isBuilding = false;
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.espacioChico),
                Text(
                  state.editingRecetaId == null
                      ? 'Armado de receta'
                      : 'Editar receta',
                  style: AppTypography.tituloPantalla
                      .copyWith(color: AppColors.textoPrincipal),
                ),
              ],
            ),
            AppButton.primary(
              key: const Key('guardar_receta_button'),
              icono: Icons.save,
              onPressed: (state.isFormValid && !state.isSaving)
                  ? () {
                      // El armador se cierra recién cuando el guardado sale
                      // bien (ver listener); si falla, queda abierto.
                      _bloc.add(const GuardarReceta());
                    }
                  : null,
              child: Text(state.isSaving ? 'Guardando...' : 'Guardar receta'),
            ),
          ],
        ),
        if (state.hayFilasIncompletas)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.espacioChico),
              child: Text(
                RecetasState.mensajeFilasIncompletas,
                key: const Key('aviso_filas_incompletas'),
                style: AppTypography.etiqueta.copyWith(color: AppColors.alerta),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.espacioGrande),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('armador_scroll'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Datos Básicos
                Card(
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.bordeTarjeta,
                    side: BorderSide(color: AppColors.bordeSuave),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.espacioGrande),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información General',
                          style: AppTypography.subtitulo
                              .copyWith(color: AppColors.textoPrincipal),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Producto elaborado: existente o nuevo (la receta lo crea)
                            Expanded(child: _buildSelectorProducto(state)),
                            const SizedBox(width: 16),
                            // Nombre de la receta
                            Expanded(
                              child: TextFormField(
                                key: const Key('input_nombre_receta'),
                                controller: _nombreCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre de la Receta *',
                                  hintText: 'Ej: Fórmula Base Chocolate',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => _bloc.add(CambiarNombreReceta(val)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                key: const Key('input_descripcion_receta'),
                                controller: _descripcionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción / Instrucciones (Opcional)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => _bloc.add(CambiarDescripcionReceta(val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                key: const Key('input_costos_adicionales'),
                                controller: _costosAdicCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Costos Adicionales (Packaging, etc.)',
                                  prefixText: r'$ ',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final adic = parseDecimal(val) ?? 0.0;
                                  _bloc.add(CambiarCostosAdicionales(adic));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Rinde: el costo del elaborado es costo de receta / rinde.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 160,
                              child: TextFormField(
                                key: const Key('input_rinde'),
                                controller: _rindeCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Rinde *',
                                  hintText: 'Ej: 8',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => _bloc.add(CambiarRinde(parseDecimal(val))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Preparación base: rinde en peso o volumen ("800 g"),
                            // así se usa como ingrediente de otras recetas.
                            if (state.esPreparacionBase)
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('input_rinde_unidad_medida_${state.rindeUnidadMedida}'),
                                  initialValue: state.rindeUnidadMedida,
                                  decoration: const InputDecoration(
                                    labelText: 'Unidad del rinde *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    for (final u in [UnidadMedida.gramo, UnidadMedida.kilo, UnidadMedida.mililitro, UnidadMedida.litro])
                                      DropdownMenuItem(value: u.codigo, child: Text(u.nombre)),
                                  ],
                                  onChanged: (u) {
                                    if (u != null) _bloc.add(CambiarRindeUnidadMedida(u));
                                  },
                                ),
                              )
                            else
                            SizedBox(
                              width: 220,
                              child: TextFormField(
                                key: const Key('input_rinde_unidad'),
                                controller: _rindeUnidadCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Qué rinde',
                                  hintText: 'porciones, unidades...',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => _bloc.add(CambiarRindeUnidad(val)),
                              ),
                            ),
                            if (state.rinde == null || state.rinde! <= 0)
                              const Padding(
                                padding: EdgeInsets.only(
                                    left: AppSpacing.espacioMedio,
                                    top: AppSpacing.espacioEstandar),
                                child: Text('Indique cuánto rinde la receta (mayor a 0).',
                                    key: Key('aviso_rinde'),
                                    style: TextStyle(color: AppColors.alerta)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sección de Insumos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingredientes / Insumos',
                      style: AppTypography.subtitulo
                          .copyWith(color: AppColors.textoPrincipal),
                    ),
                    AppButton.primary(
                      key: const Key('agregar_insumo_fila_button'),
                      icono: Icons.add,
                      child: const Text('Agregar Insumo'),
                      onPressed: () {
                        if (state.availableInsumos.isNotEmpty) {
                          // La fila nueva llega vacía: el usuario elige el insumo
                          // (solo entre los que no están en la receta) y la cantidad.
                          final usados = state.detalles.map((d) => d.articuloId).toSet();
                          final libres = state.availableInsumos
                              .where((i) => !usados.contains(i.id))
                              .toList();
                          if (libres.isEmpty) {
                            AppSnackBar.info(context,
                                'Todos los insumos disponibles ya están en la receta.');
                            return;
                          }
                          _bloc.add(const AgregarFilaVacia());
                        } else {
                          // Sin insumos no hay qué agregar: antes se agregaba uno
                          // ficticio (id 1) que se guardaba contra otro insumo real.
                          AppSnackBar.info(context,
                              'No hay insumos activos. Cárguelos en '
                              'Materia Prima antes de armar la receta.');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (state.detalles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.espacioPantalla),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.fondoSuperficie,
                      borderRadius: AppRadii.bordeTarjeta,
                      border: Border.all(color: AppColors.bordeSuave),
                    ),
                    child: Text(
                      'No hay insumos agregados en la receta. Haga clic en "Agregar Insumo".',
                      style: AppTypography.texto.copyWith(
                          color: AppColors.textoInactivo,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.detalles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final detalle = state.detalles[index];
                      // Insumos ofrecidos: los que no están en otra fila.
                      final usadosEnOtras = {
                        for (var i = 0; i < state.detalles.length; i++)
                          if (i != index) state.detalles[i].articuloId,
                      };
                      final ofrecidos = state.availableInsumos
                          .where((i) => !usadosEnOtras.contains(i.id))
                          .toList();
                      return Card(
                        // Clave estable por fila (no por posición ni por insumo): al
                        // quitar o cambiar una fila, cada widget conserva sus datos.
                        key: ValueKey('fila_insumo_${detalle.claveUi}'),
                        margin: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.bordeChico,
                          side: BorderSide(color: AppColors.bordeSuave),
                        ),
                        child: Padding(
                          key: Key('fila_insumo_$index'),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Insumo Dropdown / Name
                              Expanded(
                                flex: 3,
                                // Un insumo desactivado ya no está entre los
                                // disponibles: se muestra fijo, sin dropdown.
                                child: state.availableInsumos.isNotEmpty &&
                                        (detalle.articuloId <= 0 ||
                                            ofrecidos.any(
                                                (i) => i.id == detalle.articuloId))
                                    ? DropdownButtonFormField<int>(
                                        key: Key('selector_insumo_fila_$index'),
                                        isExpanded: true,
                                        initialValue: detalle.sinInsumo
                                            ? null
                                            : detalle.articuloId,
                                        hint: const Text('Elegir insumo'),
                                        decoration: const InputDecoration(
                                          labelText: 'Insumo',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        items: ofrecidos.map((i) {
                                          return DropdownMenuItem<int>(
                                            value: i.id,
                                            child: Text('${i.nombre} (${i.codigo})'),
                                          );
                                        }).toList(),
                                        onChanged: (selectedId) {
                                          if (selectedId != null) {
                                            final found = state.availableInsumos
                                                .firstWhere((i) => i.id == selectedId);
                                            _bloc.add(CambiarInsumoFila(index: index, insumo: found));
                                          }
                                        },
                                      )
                                    : Text(
                                        '${detalle.articuloNombre ?? 'Insumo #${detalle.articuloId}'}'
                                        '${state.availableInsumos.isEmpty ? '' : state.availableInsumos.any((i) => i.id == detalle.articuloId) ? ' (repetido)' : ' (desactivado)'}',
                                        key: Key('insumo_fijo_fila_$index'),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // Cantidad
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  key: Key('cantidad_insumo_fila_$index'),
                                  initialValue: detalle.cantidad > 0
                                      ? formatDecimal(detalle.cantidad)
                                      : '',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (val) {
                                    final cant = parseDecimal(val) ?? 0.0;
                                    _bloc.add(ActualizarCantidadFilaInsumo(
                                      index: index,
                                      cantidad: cant,
                                    ));
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Unidad: solo las de la familia del insumo.
                              _unidadDeFila(state, detalle, index),
                              const SizedBox(width: 16),

                              // Costo Unitario
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Costo Unit.',
                                      style: AppTypography.etiqueta
                                          .copyWith(color: AppColors.textoInactivo)),
                                  Text(
                                    '${formatPesos(detalle.costoUnitario, decimales: detalle.costoUnitario < 10 ? 4 : 2)}'
                                    '${UnidadMedida.deCodigo(detalle.unidadMedida) != null ? ' / ${UnidadMedida.deCodigo(detalle.unidadMedida)!.abreviatura}' : ''}',
                                    key: Key('costo_unitario_insumo_fila_$index'),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.espacioGrande),

                              // Subtotal
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Subtotal',
                                      style: AppTypography.etiqueta
                                          .copyWith(color: AppColors.textoInactivo)),
                                  Text(
                                    _currencyFormat.format(detalle.subtotal),
                                    key: Key('subtotal_insumo_fila_$index'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.exito),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.espacioMedio),

                              // Eliminar fila
                              IconButton(
                                key: Key('eliminar_insumo_fila_$index'),
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _bloc.add(RemoverFilaInsumo(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Costos y precio, en vivo.
                Card(
                  color: AppColors.exitoFondo,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.bordeTarjeta,
                    side: BorderSide(color: AppColors.bordeSuave),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.espacioGrande),
                    child: Wrap(
                      spacing: AppSpacing.espacioPantalla,
                      runSpacing: AppSpacing.espacioEstandar,
                      children: [
                        _dato('Costo total de la receta', formatPesos(state.costoTotal), const Key('costo_total_receta'),
                            detalle: 'Incluye ${state.detalles.length} insumos + ${formatPesos(state.costosAdicionales)} de adicionales'),
                        if (state.esPreparacionBase)
                          ..._resumenPreparacionBase(state)
                        else ...[
                        _dato(
                            'Costo por ${_singular(state.rindeUnidad)}',
                            state.costoPorUnidad == null ? '—' : formatPesos(state.costoPorUnidad!),
                            const Key('costo_por_unidad_receta'),
                            detalle: state.rinde == null ? 'Falta el rinde' : 'Rinde ${formatDecimal(state.rinde!)} ${state.rindeUnidad}'),
                        _dato('% de ganancia', '${formatDecimal(state.porcentajeGanancia, decimales: 2)} %',
                            const Key('porcentaje_ganancia_receta')),
                        _dato('Precio de venta', state.precioResultante == null ? '—' : formatPesos(state.precioResultante!),
                            const Key('precio_resultante_receta'),
                            detalle: 'Redondeado hacia arriba a \$100'
                                '${state.productoElegido?.precioManual == true && !state.creaProductoNuevo ? ' · precio a mano' : ''}'),
                        _dato('Ganancia por ${_singular(state.rindeUnidad)}',
                            state.gananciaResultante == null ? '—' : formatPesos(state.gananciaResultante!),
                            const Key('ganancia_resultante_receta')),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NuevaCategoriaDialog extends StatefulWidget {
  const _NuevaCategoriaDialog();

  @override
  State<_NuevaCategoriaDialog> createState() => _NuevaCategoriaDialogState();
}

class _NuevaCategoriaDialogState extends State<_NuevaCategoriaDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      titulo: 'Nueva categoría',
      tamano: TamanoDialogo.chico,
      acciones: [
        AppButton.ghost(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton.primary(
          key: const Key('crear_categoria_confirmar'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Crear'),
        ),
      ],
      child: TextField(
        key: const Key('nueva_categoria_nombre'),
        controller: _controller,
        autofocus: true,
        maxLength: 50,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
    );
  }
}
