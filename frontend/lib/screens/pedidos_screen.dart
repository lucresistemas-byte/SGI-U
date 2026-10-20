import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/pedidos/pedidos_bloc.dart';
import '../blocs/pedidos/pedidos_event.dart';
import '../blocs/pedidos/pedidos_state.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_data_table.dart';
import '../widgets/app_dialog.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/section_header.dart';
import '../widgets/metodo_pago_dropdown.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/tabla_ajustada.dart';
import '../utils/numeros.dart';

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

  TonoEstado _obtenerTonoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return TonoEstado.exito;
      case 'parcialmente pagado':
        return TonoEstado.alerta;
      case 'pendiente':
        return TonoEstado.info;
      case 'cancelado':
        return TonoEstado.error;
      default:
        return TonoEstado.neutro;
    }
  }

  void _mostrarDialogoNuevoPedido() {
    final formKey = GlobalKey<FormState>();
    final clienteCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final montoTotalCtrl = TextEditingController();
    final seniaCtrl = TextEditingController(text: '0.00');
    int? metodoPagoSeniaId = MetodoPagoDropdown.porDefecto(_bloc.state.metodosPago);
    DateTime? fechaEntregaSeleccionada;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              titulo: 'Nuevo Pedido con Seña',
              tamano: TamanoDialogo.medio,
              acciones: [
                AppButton.ghost(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                AppButton.primary(
                  key: const Key('guardar_pedido_button'),
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
                      if (metodoPagoSeniaId != null) 'metodoPagoSeniaId': metodoPagoSeniaId,
                      if (fechaEntregaSeleccionada != null)
                        'fechaEntrega': fechaEntregaSeleccionada!.toIso8601String(),
                    };
                    _bloc.add(CrearPedidoEvent(data));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Guardar Pedido'),
                ),
              ],
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
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.espacioMedio),
                    TextFormField(
                      key: const Key('pedido_telefono_input'),
                      controller: telefonoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono / WhatsApp *',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.espacioMedio),
                    TextFormField(
                      key: const Key('pedido_descripcion_input'),
                      controller: descripcionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Detalle del Pedido *',
                        hintText: 'Ej: Torta 2 pisos para 30 personas',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.espacioMedio),
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
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              final num = double.tryParse(v.replaceAll(',', '.'));
                              if (num == null || num <= 0) return 'Monto inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.espacioMedio),
                        Expanded(
                          child: TextFormField(
                            key: const Key('pedido_senia_input'),
                            controller: seniaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Seña Inicial',
                              prefixText: r'$ ',
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
                    const SizedBox(height: AppSpacing.espacioMedio),
                    MetodoPagoDropdown(
                      key: const Key('pedido_metodo_pago_dropdown'),
                      metodos: _bloc.state.metodosPago,
                      valor: metodoPagoSeniaId,
                      etiqueta: 'Método de Pago de la Seña',
                      onChanged: (id) => setDialogState(() => metodoPagoSeniaId = id),
                    ),
                    const SizedBox(height: AppSpacing.espacioMedio),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        fechaEntregaSeleccionada == null
                            ? 'Fecha de Entrega: No especificada'
                            : 'Fecha de Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaEntregaSeleccionada!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 2)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked == null || !dialogContext.mounted) return;
                        final hora = await showTimePicker(
                          context: dialogContext,
                          initialTime: const TimeOfDay(hour: 12, minute: 0),
                        );
                        if (hora == null || !dialogContext.mounted) return;
                        final fecha = DateTime(picked.year, picked.month,
                            picked.day, hora.hour, hora.minute);
                        if (fecha.isBefore(DateTime.now())) {
                          AppSnackBar.error(dialogContext,
                              'La fecha de entrega no puede ser anterior al momento actual.');
                          return;
                        }
                        setDialogState(() => fechaEntregaSeleccionada = fecha);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoAbono(Pedido pedido) {
    final formKey = GlobalKey<FormState>();
    final montoCtrl = TextEditingController(text: formatDecimal(pedido.saldo, decimales: 2));
    final notaCtrl = TextEditingController(text: 'Abono de saldo');
    int? metodoPagoId = MetodoPagoDropdown.porDefecto(_bloc.state.metodosPago);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppDialog(
              titulo: 'Registrar Abono: ${pedido.clienteNombre}',
              tamano: TamanoDialogo.medio,
              acciones: [
                AppButton.ghost(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                AppButton.primary(
                  key: const Key('confirmar_abono_button'),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final monto = double.parse(montoCtrl.text.replaceAll(',', '.'));
                    _bloc.add(RegistrarAbonoEvent(
                      pedidoId: pedido.id!,
                      monto: monto,
                      metodoPagoId: metodoPagoId,
                      nota: notaCtrl.text.trim(),
                    ));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Confirmar Abono'),
                ),
              ],
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.espacioMedio),
                      decoration: const BoxDecoration(
                        color: AppColors.fondoApp,
                        borderRadius: AppRadii.bordeChico,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pedido: ${_currencyFormat.format(pedido.montoTotal)}',
                            style: AppTypography.etiqueta
                                .copyWith(color: AppColors.textoSecundario),
                          ),
                          Text(
                            'Ya abonado: ${_currencyFormat.format(pedido.totalPagado)}',
                            style: AppTypography.etiqueta
                                .copyWith(color: AppColors.textoSecundario),
                          ),
                          const Divider(),
                          Text(
                            'Saldo Restante: ${_currencyFormat.format(pedido.saldo)}',
                            style: AppTypography.texto.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.alerta,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    TextFormField(
                      key: const Key('abono_monto_input'),
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto a Abonar *',
                        prefixText: r'$ ',
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
                    const SizedBox(height: AppSpacing.espacioMedio),
                    MetodoPagoDropdown(
                      key: const Key('abono_metodo_pago_dropdown'),
                      metodos: _bloc.state.metodosPago,
                      valor: metodoPagoId,
                      onChanged: (id) => setDialogState(() => metodoPagoId = id),
                    ),
                    const SizedBox(height: AppSpacing.espacioMedio),
                    TextFormField(
                      key: const Key('abono_nota_input'),
                      controller: notaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nota / Comentario',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Cancelar pide confirmación. Por ahora no registra la devolución de la seña.
  Future<void> _confirmarCancelar(Pedido pedido) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        titulo: 'Cancelar pedido',
        tamano: TamanoDialogo.medio,
        acciones: [
          AppButton.ghost(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          AppButton.danger(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar pedido'),
          ),
        ],
        child: Text('¿Cancelar el pedido de ${pedido.clienteNombre} '
            '(${pedido.descripcion})? No se puede deshacer.'
            '${pedido.totalPagado > 0 ? '\n\nLa seña cobrada no se registra como devuelta.' : ''}'),
      ),
    );
    if (confirmado == true && mounted) {
      _bloc.add(CancelarPedidoEvent(pedido.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        body: BlocConsumer<PedidosBloc, PedidosState>(
          bloc: _bloc,
          // Solo cuando aparece un mensaje nuevo: la recarga posterior a crear o
          // abonar volvía a emitirlo antes de que se limpiara.
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              AppSnackBar.exito(context, state.successMessage!);
              _bloc.add(const LimpiarMensajesPedidos());
            }
            if (state.errorMessage != null) {
              AppSnackBar.error(context, state.errorMessage!);
              _bloc.add(const LimpiarMensajesPedidos());
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
                    titulo: 'Pedidos por Encargo',
                    subtitulo:
                        'Gestione señas, saldos pendientes y pagos de clientes',
                    accion: AppButton.primary(
                      key: const Key('nuevo_pedido_button'),
                      icono: Icons.add,
                      onPressed: _mostrarDialogoNuevoPedido,
                      child: const Text('Nuevo Pedido'),
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
                      key: const Key('buscar_pedido_input'),
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por cliente, teléfono o detalle...',
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.textoInactivo),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _bloc.add(BuscarPedidos(val)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.espacioGrande),

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
      return const CargandoDiferido();
    }

    final items = state.filteredPedidos;

    if (items.isEmpty) {
      return const EmptyState(
        mensaje: 'No hay pedidos registrados',
        icono: Icons.assignment_outlined,
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
          separacionColumnas: AppSpacing.espacioMedio,
          margenHorizontal: AppSpacing.espacioEstandar,
          colorEncabezado: AppColors.fondoApp,
          columnas: const [
            DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Cliente')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Teléfono')),
            DataColumn(columnWidth: columnaFlexible, label: Text('Detalle')),
            DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Entrega')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Monto Total')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Abonado')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Saldo Restante')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Estado')),
            DataColumn(columnWidth: columnaAjustable, label: Text('Acciones')),
          ],
          filas: items.map((pedido) {
            final estadoVisual = pedido.estadoCalculado;

            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => _bloc.add(SeleccionarPedido(pedido)),
                    child: Text(
                      pedido.clienteNombre,
                      style: AppTypography.textoChico.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoPrincipal),
                    ),
                  ),
                ),
                DataCell(Text(pedido.clienteTelefono)),
                DataCell(
                  Text(pedido.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                DataCell(Text(pedido.fechaEntrega != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(pedido.fechaEntrega!)
                    : '-')),
                DataCell(Text(_currencyFormat.format(pedido.montoTotal))),
                DataCell(Text(_currencyFormat.format(pedido.totalPagado))),
                DataCell(
                  Text(
                    _currencyFormat.format(pedido.saldo),
                    style: AppTypography.textoChico.copyWith(
                      fontWeight: FontWeight.bold,
                      color: pedido.saldo > 0
                          ? AppColors.alerta
                          : AppColors.exito,
                    ),
                  ),
                ),
                DataCell(
                  EstadoChip(
                    etiqueta: estadoVisual,
                    tono: _obtenerTonoEstado(estadoVisual),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pedido.estado.toUpperCase() == 'CANCELADO')
                        Text(
                          'Cancelado',
                          style: AppTypography.textoChico.copyWith(
                              color: AppColors.textoInactivo,
                              fontWeight: FontWeight.w600),
                        )
                      else if (pedido.saldo > 0) ...[
                        AppButton.primary(
                          key: Key('abonar_pedido_${pedido.id}'),
                          icono: Icons.attach_money,
                          onPressed: () => _mostrarDialogoAbono(pedido),
                          child: const Text('Abonar'),
                        ),
                        const SizedBox(width: AppSpacing.espacioMinimo),
                        IconButton(
                          key: Key('cancelar_pedido_${pedido.id}'),
                          tooltip: 'Cancelar pedido',
                          icon: const Icon(Icons.cancel_outlined,
                              color: AppColors.error),
                          onPressed: pedido.id == null
                              ? null
                              : () => _confirmarCancelar(pedido),
                        ),
                      ] else
                        Text(
                          'Saldado',
                          style: AppTypography.textoChico.copyWith(
                              color: AppColors.exito,
                              fontWeight: FontWeight.w600),
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
