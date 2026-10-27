import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../models/categoria_movimiento.dart';
import '../models/metodo_pago.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_dialog.dart';
import 'metodo_pago_dropdown.dart';

class MovimientoFormDialog extends StatefulWidget {
  const MovimientoFormDialog({super.key});

  @override
  State<MovimientoFormDialog> createState() => _MovimientoFormDialogState();
}

class _MovimientoFormDialogState extends State<MovimientoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Valores por defecto
  String _tipo = 'Ingreso';
  String _categoria = CategoriaMovimiento.ingreso.first.codigo;
  int? _metodoPagoId;
  List<MetodoPago> _metodosPago = const [];

  /// Día del movimiento (por defecto hoy, sin fechas futuras).
  DateTime _fecha = DateUtils.dateOnly(DateTime.now());

  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _guardando = false;
  String? _error;

  final List<String> _tipos = ['Ingreso', 'Egreso'];
  @override
  void initState() {
    super.initState();
    _cargarMetodos();
  }

  /// Solo los activos, en el orden de Configuración; por defecto Efectivo.
  Future<void> _cargarMetodos() async {
    try {
      final metodos = await context.read<FinanzasBloc>().metodosPagoActivos();
      if (!mounted) return;
      setState(() {
        _metodosPago = metodos;
        _metodoPagoId ??= MetodoPagoDropdown.porDefecto(metodos);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar los métodos de pago.');
    }
  }

  // Validación dinámica
  bool _isFormValid() {
    final montoText = _montoController.text.trim();
    // Reemplazamos coma por punto por si usan el teclado numérico europeo
    final monto = double.tryParse(montoText.replaceAll(',', '.'));
    return _descripcionController.text.trim().isNotEmpty &&
        montoText.isNotEmpty &&
        _metodoPagoId != null &&
        monto != null &&
        monto > 0;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    // Parseo final seguro, siempre en positivo
    final monto =
        double.parse(_montoController.text.trim().replaceAll(',', '.'));

    setState(() {
      _guardando = true;
      _error = null;
    });

    // No cerramos el diálogo acá: esperamos la respuesta del backend vía
    // BlocListener (OperacionExitosa cierra; MovimientosError muestra el error)
    context.read<FinanzasBloc>().add(CrearMovimiento(
          tipo: _tipo.toUpperCase(),
          monto: monto,
          metodoPagoId: _metodoPagoId!,
          categoria: _categoria,
          descripcion: _descripcionController.text.trim(),
          fechaHora: _fechaHora(),
        ));
  }

  /// Hoy: el momento actual. Otro día: ese día a la hora actual, así queda
  /// ordenado dentro del día igual que un alta hecha en el momento.
  DateTime _fechaHora() {
    final ahora = DateTime.now();
    if (DateUtils.isSameDay(_fecha, ahora)) return ahora;
    return DateTime(_fecha.year, _fecha.month, _fecha.day, ahora.hour, ahora.minute, ahora.second);
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Fecha del movimiento',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  String _limpiarMensaje(String mensaje) {
    final limpio = mensaje.replaceAll('Exception: ', '').trim();
    return limpio.isEmpty ? 'No se pudo registrar el movimiento' : limpio;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanzasBloc, FinanzasState>(
      listenWhen: (previous, current) =>
          current is OperacionExitosa || current is MovimientosError,
      listener: (context, state) {
        if (!mounted) return;
        if (state is OperacionExitosa) {
          Navigator.of(context).pop(true);
        } else if (state is MovimientosError) {
          setState(() {
            _guardando = false;
            _error = _limpiarMensaje(state.message);
          });
        }
      },
      child: AppDialog(
        titulo: 'Agregar Nuevo Movimiento',
        tamano: TamanoDialogo.chico,
        acciones: [
          AppButton.ghost(
            onPressed: _guardando
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          AppButton.primary(
            // El botón reacciona dinámicamente y se deshabilita mientras guarda
            onPressed: (_isFormValid() && !_guardando) ? _guardar : null,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.sobreMarca),
                  )
                : const Text('Guardar'),
          ),
        ],
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha y tipo en una fila (el diálogo no crece).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('movimiento_fecha'),
                      onTap: _guardando ? null : _elegirFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          DateUtils.isSameDay(_fecha, DateTime.now())
                              ? 'Hoy (${DateFormat('dd/MM').format(_fecha)})'
                              : DateFormat('dd/MM/yyyy').format(_fecha),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.espacioMedio),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: _tipos
                          .map((tipo) => DropdownMenuItem(
                              value: tipo, child: Text(tipo)))
                          .toList(),
                      // Cada tipo tiene sus categorías: al cambiarlo se
                      // reinicia la categoría a la primera del nuevo tipo.
                      onChanged: (value) => setState(() {
                        _tipo = value!;
                        _categoria =
                            CategoriaMovimiento.paraTipo(_tipo).first.codigo;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.espacioEstandar),

              // Categoría
              DropdownButtonFormField<String>(
                // La key recrea el campo al cambiar el tipo, para que
                // tome la categoría reiniciada.
                key: ValueKey(_tipo),
                initialValue: _categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: CategoriaMovimiento.paraTipo(_tipo)
                    .map((cat) => DropdownMenuItem(
                        value: cat.codigo, child: Text(cat.etiqueta)))
                    .toList(),
                onChanged: (value) => setState(() => _categoria = value!),
              ),
              const SizedBox(height: AppSpacing.espacioEstandar),

              // Método de pago
              MetodoPagoDropdown(
                key: const Key('movimiento_metodo_pago'),
                metodos: _metodosPago,
                valor: _metodoPagoId,
                etiqueta: 'Método de Pago',
                onChanged: (id) => setState(() => _metodoPagoId = id),
              ),
              const SizedBox(height: AppSpacing.espacioEstandar),

              // Monto
              TextFormField(
                controller: _montoController,
                // Al teclear, actualiza el estado y enciende el botón.
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Monto (\$)',
                  hintText: 'Ingrese un valor positivo',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto es obligatorio';
                  }
                  final monto = double.tryParse(value.replaceAll(',', '.'));
                  if (monto == null) return 'Ingrese un número válido';
                  if (monto <= 0) {
                    return 'El monto debe ser mayor a cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.espacioEstandar),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Motivo o detalle del movimiento',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Campo obligatorio'
                    : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.espacioMedio),
                  child: Text(
                    _error!,
                    style: AppTypography.etiqueta
                        .copyWith(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
