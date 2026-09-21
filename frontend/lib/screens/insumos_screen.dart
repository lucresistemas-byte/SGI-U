import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/insumos/insumos_bloc.dart';
import '../blocs/insumos/insumos_event.dart';
import '../blocs/insumos/insumos_state.dart';
import '../models/insumo.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

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

  void _mostrarDialogoInsumo({Insumo? insumoExistente}) {
    final formKey = GlobalKey<FormState>();
    final codigoCtrl = TextEditingController(text: insumoExistente?.codigo ?? '');
    final nombreCtrl = TextEditingController(text: insumoExistente?.nombre ?? '');
    final costoCtrl = TextEditingController(
      text: insumoExistente != null
          ? insumoExistente.costoUnitario.toStringAsFixed(2)
          : '',
    );
    final stockCtrl = TextEditingController(
      text: insumoExistente != null ? insumoExistente.stockActual.toString() : '0',
    );
    final stockMinimoCtrl = TextEditingController(
      text: insumoExistente?.stockMinimo != null
          ? insumoExistente!.stockMinimo.toString()
          : '',
    );
    String unidadSeleccionada = insumoExistente?.unidadMedida ?? 'UNIDAD';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                insumoExistente == null ? 'Nuevo Insumo' : 'Editar Insumo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          key: const Key('insumo_codigo_input'),
                          controller: codigoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Código *',
                            hintText: 'Ej: HAR-001',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('insumo_nombre_input'),
                          controller: nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                            hintText: 'Ej: Harina 000',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                key: const Key('insumo_costo_input'),
                                controller: costoCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Costo Unitario *',
                                  prefixText: r'$ ',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Requerido';
                                  final num = double.tryParse(v.replaceAll(',', '.'));
                                  if (num == null || num < 0) return 'Inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                key: const Key('insumo_unidad_dropdown'),
                                value: unidadSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Unidad',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'UNIDAD', child: Text('UNIDAD')),
                                  DropdownMenuItem(value: 'KILO', child: Text('KILO')),
                                  DropdownMenuItem(value: 'GRAMO', child: Text('GRAMO')),
                                  DropdownMenuItem(value: 'LITRO', child: Text('LITRO')),
                                  DropdownMenuItem(value: 'METRO', child: Text('METRO')),
                                  DropdownMenuItem(value: 'CAJA', child: Text('CAJA')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => unidadSeleccionada = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('insumo_stock_input'),
                                controller: stockCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'Stock Actual',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: const Key('insumo_stock_minimo_input'),
                                controller: stockMinimoCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'Stock Mínimo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  key: const Key('guardar_insumo_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrincipal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final data = {
                      'codigo': codigoCtrl.text.trim(),
                      'nombre': nombreCtrl.text.trim(),
                      'costoUnitario': double.tryParse(costoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                      'unidadMedida': unidadSeleccionada,
                      'stockActual': int.tryParse(stockCtrl.text.trim()) ?? 0,
                      if (stockMinimoCtrl.text.isNotEmpty)
                        'stockMinimo': int.tryParse(stockMinimoCtrl.text.trim()),
                    };

                    if (insumoExistente == null) {
                      _bloc.add(CrearInsumoEvent(data));
                    } else {
                      _bloc.add(ActualizarInsumoEvent(insumoExistente.id!, data));
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoAjusteStock(Insumo insumo) {
    final formKey = GlobalKey<FormState>();
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController(text: 'Ajuste manual de stock');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Ajustar Stock: ${insumo.nombre}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock actual: ${insumo.stockActual} ${insumo.unidadMedida}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('ajuste_cantidad_input'),
                    controller: cantidadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad (+ para sumar, - para restar) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final cant = int.tryParse(v.trim());
                      if (cant == null || cant == 0) return 'Ingrese una cantidad válida distinta de 0';
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
                final cant = int.parse(cantidadCtrl.text.trim());
                final motivo = motivoCtrl.text.trim();
                _bloc.add(AjustarStockInsumoEvent(
                  id: insumo.id!,
                  cantidad: cant,
                  motivo: motivo,
                ));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Confirmar Ajuste'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        title: 'Materia Prima / Insumos',
        rutaActual: '/insumos',
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
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
                          color: Colors.black.withOpacity(0.04),
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
      return const Center(child: CircularProgressIndicator());
    }

    List<Insumo> items = [];
    if (state is InsumosLoaded) {
      items = state.filteredInsumos;
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
            columns: const [
              DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Costo Unitario', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Unidad', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stock Actual', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stock Mínimo', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.map((insumo) {
              final esBajoStock =
                  insumo.stockMinimo != null && insumo.stockActual <= insumo.stockMinimo!;
              return DataRow(
                cells: [
                  DataCell(Text(insumo.codigo, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(insumo.nombre)),
                  DataCell(Text(_currencyFormat.format(insumo.costoUnitario))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        insumo.unidadMedida,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${insumo.stockActual}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: esBajoStock ? Colors.redAccent : Colors.black87,
                          ),
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
                  DataCell(Text(insumo.stockMinimo != null ? '${insumo.stockMinimo}' : '-')),
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
                          message: 'Editar Insumo',
                          child: IconButton(
                            key: Key('editar_insumo_${insumo.codigo}'),
                            icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
                            onPressed: () => _mostrarDialogoInsumo(insumoExistente: insumo),
                          ),
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
    );
  }
}
