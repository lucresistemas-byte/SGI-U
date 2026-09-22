import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/recetas/recetas_bloc.dart';
import '../blocs/recetas/recetas_event.dart';
import '../blocs/recetas/recetas_state.dart';
import '../models/insumo.dart';
import '../models/receta.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        title: 'Recetas de Producción',
        rutaActual: '/recetas',
        body: BlocConsumer<RecetasBloc, RecetasState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state.successMessage != null) {
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
          const Expanded(child: Center(child: CircularProgressIndicator()))
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
                      return DataRow(
                        cells: [
                          DataCell(Text(r.espProductoNombre ?? r.espProductoCodigo, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(r.nombre)),
                          DataCell(Text('${r.detalles.length} insumos')),
                          DataCell(Text(_currencyFormat.format(r.costosAdicionales))),
                          DataCell(Text(_currencyFormat.format(r.costoTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF13894E)))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  key: Key('editar_receta_${r.id}'),
                                  icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
                                  onPressed: () => _editarReceta(r),
                                ),
                                IconButton(
                                  key: Key('eliminar_receta_${r.id}'),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    if (r.id != null) {
                                      _bloc.add(EliminarReceta(r.id!));
                                    }
                                  },
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
                        _bloc.add(const GuardarReceta());
                        setState(() {
                          _isBuilding = false;
                        });
                      }
                    : null,
              ),
            ],
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
                      // Selector de Producto
                      Expanded(
                        child: state.availableProductos.isNotEmpty
                            ? DropdownButtonFormField<String>(
                                key: const Key('selector_producto_receta'),
                                isExpanded: true,
                                initialValue: state.selectedProductoCodigo.isNotEmpty
                                    ? state.selectedProductoCodigo
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Producto Elaborado *',
                                  border: OutlineInputBorder(),
                                ),
                                items: state.availableProductos.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p.codigo,
                                    child: Text('${p.nombre} (${p.codigo})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final p = state.availableProductos.firstWhere((item) => item.codigo == val);
                                    _bloc.add(CambiarProductoReceta(codigo: p.codigo, nombre: p.nombre));
                                  }
                                },
                              )
                            : TextFormField(
                                key: const Key('selector_producto_receta'),
                                initialValue: state.selectedProductoCodigo,
                                decoration: const InputDecoration(
                                  labelText: 'Código de Producto Elaborado *',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  _bloc.add(CambiarProductoReceta(codigo: val, nombre: val));
                                },
                              ),
                      ),
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
                    _bloc.add(AgregarFilaInsumo(
                      insumo: state.availableInsumos.first,
                      cantidad: 1.0,
                    ));
                  } else {
                    _bloc.add(const AgregarFilaInsumo(
                      insumo: Insumo(
                        id: 1,
                        codigo: 'INS-001',
                        nombre: 'Insumo Base',
                        costoUnitario: 100.0,
                        unidadMedida: 'UNIDAD',
                      ),
                      cantidad: 1.0,
                    ));
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
                return Card(
                  key: Key('fila_insumo_$index'),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Insumo Dropdown / Name
                        Expanded(
                          flex: 3,
                          child: state.availableInsumos.isNotEmpty
                              ? DropdownButtonFormField<int>(
                                  key: Key('selector_insumo_fila_$index'),
                                  isExpanded: true,
                                  initialValue: detalle.materiaPrimaId > 0
                                      ? detalle.materiaPrimaId
                                      : state.availableInsumos.first.id,
                                  decoration: const InputDecoration(
                                    labelText: 'Insumo',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: state.availableInsumos.map((i) {
                                    return DropdownMenuItem<int>(
                                      value: i.id,
                                      child: Text('${i.nombre} (${i.codigo})'),
                                    );
                                  }).toList(),
                                  onChanged: (selectedId) {
                                    if (selectedId != null) {
                                      final found = state.availableInsumos
                                          .firstWhere((i) => i.id == selectedId);
                                      _bloc.add(RemoverFilaInsumo(index));
                                      _bloc.add(AgregarFilaInsumo(
                                        insumo: found,
                                        cantidad: detalle.cantidad,
                                      ));
                                    }
                                  },
                                )
                              : Text(
                                  detalle.materiaPrimaNombre ?? 'Insumo #${detalle.materiaPrimaId}',
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
                            detalle.unidadMedida,
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
