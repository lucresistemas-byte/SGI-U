import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/recetas/recetas_bloc.dart';
import '../blocs/recetas/recetas_event.dart';
import '../blocs/recetas/recetas_state.dart';
import '../models/receta.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/cargando_diferido.dart';

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
    if (widget.recetasBloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _iniciarNuevaReceta() {
    _nombreCtrl.clear();
    _descripcionCtrl.clear();
    _costosAdicCtrl.text = '0.00';
    _bloc.add(const IniciarNuevaReceta());
    setState(() {
      _isBuilding = true;
    });
  }

  void _editarReceta(Receta receta) {
    _nombreCtrl.text = receta.nombre;
    _descripcionCtrl.text = receta.descripcion ?? '';
    _costosAdicCtrl.text = receta.costosAdicionales.toStringAsFixed(2);
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
              const Chip(
                key: Key('producto_inactivo_armador'),
                label: Text('Producto inactivo'),
                visualDensity: VisualDensity.compact,
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
          const Text(
            'No hay productos elaborados sin receta. Cree uno nuevo.',
            key: Key('sin_elaborados_sin_receta'),
            style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
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
            Expanded(
              child: TextFormField(
                key: const Key('nuevo_producto_codigo'),
                initialValue: state.nuevoProductoCodigo,
                decoration: const InputDecoration(
                  labelText: 'Código (opcional)',
                  hintText: 'Si lo deja vacío: ELA-0001',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _bloc.add(ActualizarProductoNuevoReceta(codigo: v)),
              ),
            ),
            const SizedBox(width: 12),
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
        if (state.availableCategorias.isNotEmpty)
          DropdownButtonFormField<int?>(
            key: const Key('nuevo_producto_categoria'),
            isExpanded: true,
            initialValue: state.nuevoProductoCategoriaId,
            decoration: const InputDecoration(
              labelText: 'Categoría (opcional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
              ...state.availableCategorias.map(
                  (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre))),
            ],
            onChanged: (v) => _bloc.add(v == null
                ? const ActualizarProductoNuevoReceta(quitarCategoria: true)
                : ActualizarProductoNuevoReceta(categoriaId: v)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.verdePrincipal,
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.redAccent,
                ),
              );
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recetas de Fabricación',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Defina insumos y costos para productos elaborados',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              key: const Key('nueva_receta_button'),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Receta'),
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
              onPressed: _iniciarNuevaReceta,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (state.isLoading && state.recetas.isEmpty)
          const Expanded(child: CargandoDiferido())
        else if (state.recetas.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'No hay recetas registradas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Container(
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
                child: SingleChildScrollView(
                  // Scroll horizontal: con nombres largos o el chip "Producto
                  // inactivo", la tabla puede ser más ancha que la pantalla.
                  child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text('Producto Elaborado', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre Receta', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Insumos', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Costos Adic.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Costo Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: state.recetas.map((r) {
                      // La receta siempre se ve; si su producto está
                      // desactivado, se marca (no se vende en el POS).
                      final atenuado = r.productoActivo
                          ? null
                          : const TextStyle(color: Color(0xFF94A3B8));
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
                                const SizedBox(width: 8),
                                const Chip(
                                  key: Key('producto_inactivo_chip'),
                                  label: Text('Producto inactivo'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ],
                          )),
                          DataCell(Text(r.nombre, style: atenuado)),
                          DataCell(Text('${r.detalles.length} insumos', style: atenuado)),
                          DataCell(Text(_currencyFormat.format(r.costosAdicionales), style: atenuado)),
                          DataCell(Text(_currencyFormat.format(r.costoTotal),
                              style: atenuado ??
                                  const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF13894E)))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('editar_receta_${r.id}'),
                                  icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
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
            ),
          ),
      ],
    );
  }

  // --- BUILDER VIEW ---
  Widget _buildRecipeBuilder(BuildContext context, RecetasState state) {
    return SingleChildScrollView(
      child: Column(
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
                  const SizedBox(width: 8),
                  Text(
                    state.editingRecetaId == null
                        ? 'Armador de Receta'
                        : 'Editar Receta',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                key: const Key('guardar_receta_button'),
                icon: const Icon(Icons.save),
                label: Text(state.isSaving ? 'Guardando...' : 'Guardar Receta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdePrincipal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (state.isFormValid && !state.isSaving)
                    ? () {
                        // El armador se cierra recién cuando el guardado sale
                        // bien (ver listener); si falla, queda abierto.
                        _bloc.add(const GuardarReceta());
                      }
                    : null,
              ),
            ],
          ),
          if (state.hayFilasIncompletas)
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  RecetasState.mensajeFilasIncompletas,
                  key: Key('aviso_filas_incompletas'),
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Card Datos Básicos
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información General',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            final adic = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            _bloc.add(CambiarCostosAdicionales(adic));
                          },
                        ),
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
              const Text(
                'Ingredientes / Insumos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('agregar_insumo_fila_button'),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Insumo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (state.availableInsumos.isNotEmpty) {
                    // La fila nueva llega vacía: el usuario elige el insumo
                    // (solo entre los que no están en la receta) y la cantidad.
                    final usados = state.detalles.map((d) => d.materiaPrimaId).toSet();
                    final libres = state.availableInsumos
                        .where((i) => !usados.contains(i.id))
                        .toList();
                    if (libres.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Todos los insumos disponibles ya están en la receta.'),
                        ),
                      );
                      return;
                    }
                    _bloc.add(const AgregarFilaVacia());
                  } else {
                    // Sin insumos no hay qué agregar: antes se agregaba uno
                    // ficticio (id 1) que se guardaba contra otro insumo real.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No hay insumos activos. Cárguelos en '
                            'Materia Prima antes de armar la receta.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (state.detalles.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No hay insumos agregados en la receta. Haga clic en "Agregar Insumo".',
                style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
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
                    if (i != index) state.detalles[i].materiaPrimaId,
                };
                final ofrecidos = state.availableInsumos
                    .where((i) => !usadosEnOtras.contains(i.id))
                    .toList();
                return Card(
                  // Clave estable por fila (no por posición ni por insumo): al
                  // quitar o cambiar una fila, cada widget conserva sus datos.
                  key: ValueKey('fila_insumo_${detalle.claveUi}'),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                                  (detalle.materiaPrimaId <= 0 ||
                                      ofrecidos.any(
                                          (i) => i.id == detalle.materiaPrimaId))
                              ? DropdownButtonFormField<int>(
                                  key: Key('selector_insumo_fila_$index'),
                                  isExpanded: true,
                                  initialValue: detalle.sinInsumo
                                      ? null
                                      : detalle.materiaPrimaId,
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
                                  '${detalle.materiaPrimaNombre ?? 'Insumo #${detalle.materiaPrimaId}'}'
                                  '${state.availableInsumos.isEmpty ? '' : state.availableInsumos.any((i) => i.id == detalle.materiaPrimaId) ? ' (repetido)' : ' (desactivado)'}',
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
                                ? detalle.cantidad.toString()
                                : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              final cant = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                              _bloc.add(ActualizarCantidadFilaInsumo(
                                index: index,
                                cantidad: cant,
                              ));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Unidad
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            detalle.unidadMedida.isEmpty ? '—' : detalle.unidadMedida,
                            key: Key('unidad_insumo_fila_$index'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Costo Unitario
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Costo Unit.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              _currencyFormat.format(detalle.costoUnitario),
                              key: Key('costo_unitario_insumo_fila_$index'),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Subtotal
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              _currencyFormat.format(detalle.subtotal),
                              key: Key('subtotal_insumo_fila_$index'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF13894E)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Eliminar fila
                        IconButton(
                          key: Key('eliminar_insumo_fila_$index'),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _bloc.add(RemoverFilaInsumo(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),

          // Total Cost Card
          Card(
            color: const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFBBF7D0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Costo de Producción por Receta',
                        style: TextStyle(fontSize: 14, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Incluye ${state.detalles.length} insumos + ${_currencyFormat.format(state.costosAdicionales)} de adicionales',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  Text(
                    _currencyFormat.format(state.costoTotal),
                    key: const Key('costo_total_receta'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
