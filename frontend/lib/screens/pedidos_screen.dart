import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/pedidos/pedidos_bloc.dart';
import '../blocs/pedidos/pedidos_event.dart';
import '../blocs/pedidos/pedidos_state.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';

class PedidosScreen extends StatefulWidget {
  final PedidosBloc? pedidosBloc;
  final ApiService? apiService;

  const PedidosScreen({
    super.key,
    this.pedidosBloc,
    this.apiService,
  });

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  late final PedidosBloc _bloc;
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _bloc = widget.pedidosBloc ??
        PedidosBloc(apiService: widget.apiService ?? ApiService());
    _bloc.add(const CargarPedidos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.pedidosBloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return const Color(0xFF16A34A);
      case 'parcialmente pagado':
        return const Color(0xFFD97706);
      case 'pendiente':
        return const Color(0xFF2563EB);
      case 'cancelado':
        return Colors.redAccent;
      default:
        return const Color(0xFF64748B);
    }
  }

  void _mostrarDialogoNuevoPedido() {
    final formKey = GlobalKey<FormState>();
    final clienteCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final montoTotalCtrl = TextEditingController();
    final seniaCtrl = TextEditingController(text: '0.00');
    String metodoPagoSenia = 'EFECTIVO';
    DateTime? fechaEntregaSeleccionada;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Nuevo Pedido con Seña',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          key: const Key('pedido_cliente_input'),
                          controller: clienteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Cliente *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('pedido_telefono_input'),
                          controller: telefonoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono / WhatsApp *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('pedido_descripcion_input'),
                          controller: descripcionCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Detalle del Pedido *',
                            hintText: 'Ej: Torta 2 pisos para 30 personas',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('pedido_monto_total_input'),
                                controller: montoTotalCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Monto Total *',
                                  prefixText: r'$ ',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Requerido';
                                  final num = double.tryParse(v.replaceAll(',', '.'));
                                  if (num == null || num <= 0) return 'Monto inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: const Key('pedido_senia_input'),
                                controller: seniaCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Seña Inicial',
                                  prefixText: r'$ ',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final sen = double.tryParse(v.replaceAll(',', '.'));
                                  final tot = double.tryParse(montoTotalCtrl.text.replaceAll(',', '.')) ?? 0;
                                  if (sen == null || sen < 0) return 'Seña inválida';
                                  if (sen > tot) return 'Supera el total';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const Key('pedido_metodo_pago_dropdown'),
                          value: metodoPagoSenia,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Método de Pago de la Seña',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                            DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferencia')),
                            DropdownMenuItem(value: 'DEBITO', child: Text('Débito')),
                            DropdownMenuItem(value: 'CREDITO', child: Text('Crédito')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => metodoPagoSenia = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            fechaEntregaSeleccionada == null
                                ? 'Fecha de Entrega: No especificada'
                                : 'Fecha de Entrega: ${DateFormat('dd/MM/yyyy').format(fechaEntregaSeleccionada!)}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 2)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => fechaEntregaSeleccionada = picked);
                            }
                          },
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
                  key: const Key('guardar_pedido_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrincipal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final total = double.parse(montoTotalCtrl.text.replaceAll(',', '.'));
                    final sen = double.tryParse(seniaCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    final data = {
                      'clienteNombre': clienteCtrl.text.trim(),
                      'clienteTelefono': telefonoCtrl.text.trim(),
                      'descripcion': descripcionCtrl.text.trim(),
                      'montoTotal': total,
                      'senia': sen,
                      'metodoPagoSenia': metodoPagoSenia,
                      if (fechaEntregaSeleccionada != null)
                        'fechaEntrega': fechaEntregaSeleccionada!.toIso8601String(),
                    };
                    _bloc.add(CrearPedidoEvent(data));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Guardar Pedido'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoAbono(Pedido pedido) {
    final formKey = GlobalKey<FormState>();
    final montoCtrl = TextEditingController(text: pedido.saldo.toStringAsFixed(2));
    final notaCtrl = TextEditingController(text: 'Abono de saldo');
    String metodoPago = 'EFECTIVO';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Registrar Abono: ${pedido.clienteNombre}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pedido: ${_currencyFormat.format(pedido.montoTotal)}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                            Text(
                              'Ya abonado: ${_currencyFormat.format(pedido.totalPagado)}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                            const Divider(height: 12),
                            Text(
                              'Saldo Restante: ${_currencyFormat.format(pedido.saldo)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('abono_monto_input'),
                        controller: montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto a Abonar *',
                          prefixText: r'$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final monto = double.tryParse(v.replaceAll(',', '.'));
                          if (monto == null || monto <= 0) return 'Monto inválido';
                          if (monto > pedido.saldo + 0.001) {
                            return 'El monto no puede superar el saldo pendiente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: const Key('abono_metodo_pago_dropdown'),
                        value: metodoPago,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                          DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferencia')),
                          DropdownMenuItem(value: 'DEBITO', child: Text('Débito')),
                          DropdownMenuItem(value: 'CREDITO', child: Text('Crédito')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => metodoPago = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('abono_nota_input'),
                        controller: notaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nota / Comentario',
                          border: OutlineInputBorder(),
                        ),
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
                  key: const Key('confirmar_abono_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrincipal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final monto = double.parse(montoCtrl.text.replaceAll(',', '.'));
                    _bloc.add(RegistrarAbonoEvent(
                      pedidoId: pedido.id!,
                      monto: monto,
                      metodoPago: metodoPago,
                      nota: notaCtrl.text.trim(),
                    ));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Confirmar Abono'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        title: 'Pedidos con Seña',
        rutaActual: '/pedidos',
        body: BlocConsumer<PedidosBloc, PedidosState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.verdePrincipal,
                ),
              );
              _bloc.add(const LimpiarMensajesPedidos());
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.redAccent,
                ),
              );
              _bloc.add(const LimpiarMensajesPedidos());
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
                              'Pedidos por Encargo',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestione señas, saldos pendientes y pagos de clientes',
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
                        key: const Key('nuevo_pedido_button'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Pedido'),
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
                        onPressed: _mostrarDialogoNuevoPedido,
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
                      key: const Key('buscar_pedido_input'),
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por cliente, teléfono o detalle...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _bloc.add(BuscarPedidos(val)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tabla de Pedidos
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

  Widget _buildBody(PedidosState state) {
    if (state.isLoading && state.pedidos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = state.filteredPedidos;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No hay pedidos registrados',
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
                DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Detalle', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Monto Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Abonado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Saldo Restante', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: items.map((pedido) {
                final estadoVisual = pedido.estadoCalculado;
                final estadoColor = _obtenerColorEstado(estadoVisual);

                return DataRow(
                  cells: [
                    DataCell(
                      InkWell(
                        onTap: () => _bloc.add(SeleccionarPedido(pedido)),
                        child: Text(
                          pedido.clienteNombre,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    DataCell(Text(pedido.clienteTelefono)),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(pedido.descripcion, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(Text(_currencyFormat.format(pedido.montoTotal))),
                    DataCell(Text(_currencyFormat.format(pedido.totalPagado))),
                    DataCell(
                      Text(
                        _currencyFormat.format(pedido.saldo),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: pedido.saldo > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: estadoColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          estadoVisual,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: estadoColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pedido.saldo > 0 && pedido.estado.toUpperCase() != 'CANCELADO')
                            ElevatedButton.icon(
                              key: Key('abonar_pedido_${pedido.id}'),
                              icon: const Icon(Icons.attach_money, size: 16),
                              label: const Text('Abonar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => _mostrarDialogoAbono(pedido),
                            )
                          else
                            const Text(
                              'Saldado',
                              style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
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
