import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart' show AppTypography;
import '../utils/numeros.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import 'app_button.dart';
import 'app_dialog.dart';

class ProductoFormDialog extends StatefulWidget {
  final Product? productoAEditar;
  const ProductoFormDialog({super.key, this.productoAEditar});

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _costoController;
  late TextEditingController _porcentajeController;
  late bool _activo;

  /// Preparación base: solo aplica a productos elaborados.
  late bool _preparacionBase;

  // Stock inicial (solo creación)
  late TextEditingController _stockInicialController;
  // Controles de ajuste (solo edición)
  late TextEditingController _ajusteCantidadController;
  late TextEditingController _stockMinimoController;
  String _ajusteTipo = 'sumar';

  /// Tipo del movimiento: COMPRA o AJUSTE al sumar; AJUSTE o MERMA al restar.
  String _ajusteMovimiento = 'COMPRA';
  late final TextEditingController _ajusteMotivoController = TextEditingController(text: 'Ajuste manual');

  /// Elaborados y paquetes suman stock produciendo (botón Producir de la lista).
  bool get _soloResta => _esEdicion && widget.productoAEditar!.seProduce;

  /// Movimientos posibles según sume o reste.
  Map<String, String> get _movimientos => _ajusteTipo == 'sumar'
      ? const {'COMPRA': 'Compra', 'AJUSTE': 'Ajuste'}
      : const {'AJUSTE': 'Ajuste', 'MERMA': 'Merma'};
  int _stockActualMostrado = 0;

  static const List<String> unidadesMedidaDisponibles = [
    'UNIDAD',
    'KILO',
    'GRAMO',
    'CAJA',
    'METRO',
    'LITRO',
  ];
  late String _unidadMedida;

  bool get _esEdicion => widget.productoAEditar != null;

  /// true = precio fijado a mano (MANUAL): se conserva mientras deje el %; si
  /// no, el precio sale del costo y el % (MARGEN), hacia arriba a $100.
  late bool _precioManual;

  /// El costo de un elaborado sale de su receta (no se edita acá).
  bool get _costoCalculado => _esEdicion && widget.productoAEditar!.esElaborado;

  double get _costo => parseDecimal(_costoController.text) ?? 0;
  double get _porcentaje => parseDecimal(_porcentajeController.text) ?? 0;
  double? get _precio => parseDecimal(_precioController.text);

  /// Precio que calcula el sistema con el % (hacia arriba a $100).
  double get _minimo => precioMinimo(_costo, _porcentaje);

  /// Lo mínimo que puede valer un precio a mano: costo × (1 + %), sin redondear.
  double get _minimoManual => minimoExacto(_costo, _porcentaje);

  String _texto(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  /// Sin precio a mano, el precio sigue al costo y al %.
  void _recalcularPrecio() {
    if (_precioManual) return;
    if (_costo > 0) _precioController.text = _texto(_minimo);
  }
  String? _backendError;

  @override
  void initState() {
    super.initState();
    final prod = widget.productoAEditar;
    _nombreController = TextEditingController(
        text: _esEdicion ? prod!.nombre : '');
    _precioController = TextEditingController(
        text: _esEdicion
            ? (prod!.precioUnitario % 1 == 0
                ? prod.precioUnitario.toInt().toString()
                : prod.precioUnitario.toString())
            : '');
    _costoController = TextEditingController(
        text: _esEdicion && prod!.precioCosto != null && prod.precioCosto! > 0
            ? (prod.precioCosto! % 1 == 0
                ? prod.precioCosto!.toInt().toString()
                : prod.precioCosto!.toString())
            : '');
    _porcentajeController = TextEditingController(
        text: _esEdicion && prod!.porcentajeGanancia != null && prod.porcentajeGanancia! > 0
            ? (prod.porcentajeGanancia! % 1 == 0
                ? prod.porcentajeGanancia!.toInt().toString()
                : prod.porcentajeGanancia!.toString())
            : '');
    _activo = _esEdicion ? prod!.activo : true;
    _precioManual = _esEdicion && prod!.precioManual;
    _preparacionBase = _esEdicion && prod!.esPreparacionBase;
    _unidadMedida = prod?.unidadMedida ?? 'UNIDAD';
    _stockInicialController = TextEditingController(text: '0');
    _ajusteCantidadController = TextEditingController(text: '0');
    _stockMinimoController =
        TextEditingController(text: '${prod?.stockMinimo ?? 0}');
    if (_esEdicion) {
      _stockActualMostrado = prod!.stockActual;
      if (prod.seProduce) {
        _ajusteTipo = 'restar';
        _ajusteMovimiento = 'AJUSTE';
      }
    }

    // Listeners para actualizar estado del diálogo cuando cambian campos
    _nombreController.addListener(() => setState(() {}));
    _precioController.addListener(() => setState(() {}));
    _costoController.addListener(() => setState(() {}));
    _porcentajeController.addListener(() => setState(() {}));
    _stockInicialController.addListener(() => setState(() {}));
    _ajusteCantidadController.addListener(() => setState(() {}));
    _ajusteMotivoController.addListener(() => setState(() {}));
    _stockMinimoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _costoController.dispose();
    _porcentajeController.dispose();
    _stockInicialController.dispose();
    _ajusteCantidadController.dispose();
    _stockMinimoController.dispose();
    _ajusteMotivoController.dispose();
    super.dispose();
  }

  void _onCostoChanged(String val) => _recalcularPrecio();

  void _onPorcentajeChanged(String val) => _recalcularPrecio();

  /// Escribir un precio distinto del que da el % lo deja fijado a mano.
  void _onPrecioVentaChanged(String val) {
    final venta = parseDecimal(val);
    if (venta == null || venta <= 0) return;
    final manual = _costo <= 0 || venta != _minimo;
    if (manual != _precioManual) setState(() => _precioManual = manual);
  }

  bool _isPrecioValido() {
    final precioText = _precioController.text.trim();
    if (precioText.isEmpty) return false;
    // Aceptar coma como separador decimal
    final normalized = precioText.replaceAll(',', '.');
    final precio = double.tryParse(normalized);
    // A mano: no por debajo del mínimo que deja el %.
    return precio != null && precio > 0 && (!_precioManual || precio >= _minimoManual - 0.005);
  }

  bool _isStockInicialValido() {
    if (_esEdicion) return true;
    final stockText = _stockInicialController.text.trim();
    if (stockText.isEmpty) return false;
    final stock = int.tryParse(stockText);
    return stock != null && stock >= 0;
  }

  bool _isStockMinimoValido() {
    final minimo = int.tryParse(_stockMinimoController.text.trim());
    return minimo != null && minimo >= 0;
  }

  bool _isAjusteValido() {
    if (!_esEdicion) return true;
    final cantidad = int.tryParse(_ajusteCantidadController.text.trim()) ?? 0;
    // Sin cantidad ingresada: se guarda solo el dato, sin ajuste de stock.
    if (cantidad <= 0) return true;
    if (_ajusteTipo == 'restar' && cantidad > _stockActualMostrado) {
      return false;
    }
    // Todo cambio de stock lleva motivo.
    return _ajusteMotivoController.text.trim().isNotEmpty;
  }

  bool _isFormValid() {
    final nombreValido = _nombreController.text.trim().isNotEmpty;
    final precioValido = _isPrecioValido();
    final stockInicialValido = _isStockInicialValido();
    final ajusteValido = _isAjusteValido();
    return nombreValido &&
        precioValido &&
        stockInicialValido &&
        _isStockMinimoValido() &&
        ajusteValido;
  }

  Map<String, dynamic> _buildProductData() {
    final costoVal = _costoController.text.trim().isNotEmpty
        ? double.tryParse(_costoController.text.trim().replaceAll(',', '.')) ?? 0.0
        : 0.0;
    final porcentajeVal = _porcentajeController.text.trim().isNotEmpty
        ? double.tryParse(_porcentajeController.text.trim().replaceAll(',', '.')) ?? 0.0
        : 0.0;

    final data = <String, dynamic>{
      // Al crear, el código lo genera el sistema (REV-0001, ...).
      if (_esEdicion) 'codigo': widget.productoAEditar!.codigo,
      // Desde Productos solo se crea reventa; los elaborados nacen en Recetas.
      if (!_esEdicion) 'tipo': 'REVENTA',
      'nombre': _nombreController.text.trim(),
      'precioUnitario': double.parse(
          _precioController.text.trim().replaceAll(',', '.')), // aceptar coma
      'activo': _activo,
      if (_esEdicion && widget.productoAEditar!.esElaborado) 'vendible': !_preparacionBase,
      'unidadMedida': _unidadMedida,
      'unidad_medida': _unidadMedida,
      'precioCosto': costoVal,
      'precio_costo': costoVal,
      'porcentajeGanancia': porcentajeVal,
      'porcentaje_ganancia': porcentajeVal,
      'modoPrecio': _precioManual ? 'MANUAL' : 'MARGEN',
      'stockMinimo': int.parse(_stockMinimoController.text.trim()),
    };

    if (widget.productoAEditar?.categoria != null) {
      data['categoria'] = widget.productoAEditar!.categoria;
    }

    if (!_esEdicion) {
      data['stockActual'] = int.parse(_stockInicialController.text.trim());
    }
    return data;
  }

  /// Delta de stock firmado: positivo suma, negativo resta. Null si el
  /// usuario no ingresó una cantidad. El backend lo aplica via /stock.
  int? _calcularStockAjuste() {
    if (!_esEdicion) return null;
    final cantidad =
        int.tryParse(_ajusteCantidadController.text.trim()) ?? 0;
    if (cantidad <= 0) return null;
    return _ajusteTipo == 'sumar' ? cantidad : -cantidad;
  }

  int _calcularStockResultante() {
    int cantidad = int.tryParse(_ajusteCantidadController.text.trim()) ?? 0;
    return _ajusteTipo == 'sumar'
        ? _stockActualMostrado + cantidad
        : _stockActualMostrado - cantidad;
  }

  void _guardarProducto() {
    if (!_isFormValid()) return;

    final productoData = _buildProductData();
    // Limpiar error anterior
    setState(() => _backendError = null);

    if (_esEdicion) {
      context.read<PosBloc>().add(UpdateProduct(
            widget.productoAEditar!.codigo,
            productoData,
            stockAjuste: _calcularStockAjuste(),
            stockMotivo: _ajusteMotivoController.text.trim(),
            stockTipo: _ajusteMovimiento,
          ));
    } else {
      context.read<PosBloc>().add(CreateProduct(productoData));
    }
  }

  /// Ganancia por unidad en $ y %, el mínimo del % y el modo del precio.
  Widget _resumenPrecio() {
    final precio = _precio;
    // A mano se guarda tal cual; calculado ya viene redondeado.
    final redondeado = precio;
    final ganancia = redondeado == null ? null : redondeado - _costo;
    final real = _costo > 0 && ganancia != null ? ganancia / _costo * 100 : null;
    final bajoMinimo = _precioManual && redondeado != null && redondeado < _minimoManual - 0.005;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ganancia == null
              ? 'Ganancia por unidad: —'
              : 'Ganancia por unidad: ${formatPesos(ganancia)}'
                  '${real != null ? ' (${formatDecimal(real, decimales: 2)} %)' : ''}',
          key: const Key('ganancia_pesos_form'),
          style: AppTypography.textoChico.copyWith(
              fontWeight: FontWeight.w600, color: AppColors.marca),
        ),
        Text(
          bajoMinimo
              ? 'Con ${formatDecimal(_porcentaje, decimales: 2)} % de ganancia el mínimo es ${formatPesos(_minimoManual)}.'
              : _precioManual
                  ? 'Precio a mano: se guarda tal cual (sin redondear) mientras deje el ${formatDecimal(_porcentaje, decimales: 2)} %; '
                      'si el costo sube, sube solo al mínimo.'
                  : 'El precio sigue al costo y al %, redondeado hacia arriba a \$100.',
          key: const Key('modo_precio_form'),
          style: AppTypography.etiqueta.copyWith(
              color: bajoMinimo ? AppColors.error : AppColors.textoInactivo),
        ),
        if (_precioManual)
          TextButton(
            key: const Key('precio_por_margen_button'),
            onPressed: () => setState(() {
              _precioManual = false;
              _recalcularPrecio();
            }),
            child: const Text('Volver a calcular con el %'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          setState(() => _backendError = state.errorMessage);
          // Opcional: limpiar el error global después de mostrarlo localmente
          Future.delayed(Duration.zero, () {
            if (!context.mounted) return;
            context.read<PosBloc>().add(const ClearError());
          });
        }
        if (state.successMessage != null) {
          // Éxito: cerrar el diálogo
          Navigator.of(context).pop();
          // Limpiar el mensaje global
          context.read<PosBloc>().add(const ClearSuccess());
        }
      },
      child: AppDialog(
        titulo: _esEdicion ? 'Editar Producto' : 'Nuevo Producto',
        acciones: [
          AppButton.ghost(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          AppButton.primary(
            onPressed: _isFormValid() ? _guardarProducto : null,
            child: const Text('Guardar Producto'),
          ),
        ],
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            // No agregamos listeners aquí (se agregan en initState)

            return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tipo: desde acá solo se crea reventa; al editar no cambia.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _esEdicion
                            ? 'Tipo: ${widget.productoAEditar!.esElaborado ? 'Elaborado' : 'Reventa'}'
                            : 'Tipo: Reventa. Los productos elaborados se crean desde Recetas.',
                        key: const Key('tipo_producto_form'),
                        style: AppTypography.textoChico
                            .copyWith(color: AppColors.textoSecundario),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.espacioMedio),
                    // Código: lo genera el sistema; solo se muestra al editar.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _esEdicion
                            ? 'Código: ${widget.productoAEditar!.codigo}'
                            : 'El código se genera automáticamente al guardar.',
                        key: const Key('codigo_producto_form'),
                        style: AppTypography.textoChico
                            .copyWith(color: AppColors.textoSecundario),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Producto'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    // Costo y Margen (% Ganancia)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('producto_form_costo_field'),
                            controller: _costoController,
                            readOnly: _costoCalculado,
                            decoration: InputDecoration(
                              labelText: 'Precio de Costo (\$)',
                              hintText: 'Ej: 100',
                              helperText: _costoCalculado ? 'Sale de la receta' : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _onCostoChanged,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final normalized = value.trim().replaceAll(',', '.');
                              final costo = double.tryParse(normalized);
                              if (costo == null) return 'Valor numérico';
                              if (costo < 0) return 'No negativo';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.espacioEstandar),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('producto_form_porcentaje_field'),
                            controller: _porcentajeController,
                            decoration: const InputDecoration(
                              labelText: '% Ganancia',
                              hintText: 'Ej: 50',
                              suffixText: '%',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _onPorcentajeChanged,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final normalized = value.trim().replaceAll(',', '.');
                              final pct = double.tryParse(normalized);
                              if (pct == null) return 'Valor numérico';
                              if (pct < 0) return 'No negativo';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    // Precio de Venta
                    TextFormField(
                      key: const ValueKey('producto_form_precio_field'),
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario (\$)',
                        hintText: 'Debe ser mayor a 0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onPrecioVentaChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El precio es obligatorio.';
                        }
                        final normalized = value.trim().replaceAll(',', '.');
                        final precio = double.tryParse(normalized);
                        if (precio == null) {
                          return 'Ingrese un valor numérico válido.';
                        }
                        if (precio <= 0) {
                          return 'El precio debe ser mayor a \$0.';
                        }
                        if (normalized.contains('.') &&
                            normalized.split('.')[1].length > 2) {
                          return 'Máximo 2 decimales permitidos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.espacioChico),
                    _resumenPrecio(),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    // Unidad de Medida
                    DropdownButtonFormField<String>(
                      key: const ValueKey('producto_form_unidad_medida_dropdown'),
                      initialValue: _unidadMedida,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de Medida',
                      ),
                      items: unidadesMedidaDisponibles.map((u) {
                        return DropdownMenuItem<String>(
                          key: ValueKey('unidad_item_$u'),
                          value: u,
                          child: Text(u),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => _unidadMedida = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    TextFormField(
                      key: const Key('producto_stock_minimo_input'),
                      controller: _stockMinimoController,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo: avisar cuando queden menos de',
                        suffixText: 'unidades',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final minimo = int.tryParse(value?.trim() ?? '');
                        if (minimo == null) return 'Debe ser un número entero';
                        if (minimo < 0) return 'No puede ser negativo';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.espacioEstandar),
                    // Stock inicial (creación)
                    if (!_esEdicion) ...[
                      TextFormField(
                        controller: _stockInicialController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Inicial',
                          hintText: 'Cantidad disponible',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          final stock = int.tryParse(value);
                          if (stock == null) return 'Debe ser un número entero';
                          if (stock < 0) {
                            return 'El stock no puede ser negativo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.espacioEstandar),
                    ] else ...[
                      // Ajuste de stock (edición)
                       Container(
                         padding: const EdgeInsets.all(AppSpacing.espacioMedio),
                         decoration: BoxDecoration(
                           color: AppColors.fondoAlternativo,
                           borderRadius: AppRadii.bordeChico,
                           border: Border.all(color: AppColors.borde),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                                 'Stock actual: $_stockActualMostrado ${_unidadMedida == 'UNIDAD' ? 'unidades' : _unidadMedida}',
                                 style: AppTypography.texto.copyWith(
                                     fontWeight: FontWeight.bold)),
                             const SizedBox(height: AppSpacing.espacioMedio),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _ajusteTipo,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Acción'),
                                    items: [
                                      if (!_soloResta)
                                        const DropdownMenuItem(
                                            value: 'sumar',
                                            child: Text('Sumar stock')),
                                      const DropdownMenuItem(
                                          value: 'restar',
                                          child: Text('Restar stock')),
                                    ],
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        _ajusteTipo = value!;
                                        _ajusteMovimiento = _movimientos.keys.first;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.espacioEstandar),
                                Expanded(
                                  child: TextFormField(
                                    controller: _ajusteCantidadController,
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                      hintText: '0',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return null;
                                      }
                                      final cant = int.tryParse(value);
                                      if (cant == null) return 'Número entero';
                                      if (cant <= 0) {
                                        return 'Debe ser mayor a 0';
                                      }
                                      if (_ajusteTipo == 'restar' &&
                                          cant > _stockActualMostrado) {
                                        return 'No puede quedar stock negativo';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.espacioMedio),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('ajuste_movimiento_$_ajusteTipo'),
                                    initialValue: _ajusteMovimiento,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Tipo'),
                                    items: [
                                      for (final m in _movimientos.entries)
                                        DropdownMenuItem(value: m.key, child: Text(m.value)),
                                    ],
                                    onChanged: (value) => setStateDialog(() => _ajusteMovimiento = value!),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.espacioEstandar),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    key: const Key('ajuste_motivo_producto_input'),
                                    controller: _ajusteMotivoController,
                                    decoration: const InputDecoration(labelText: 'Motivo *'),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                                  ),
                                ),
                              ],
                            ),
                            if (_soloResta)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.espacioChico),
                                child: Text(
                                  'Para sumar stock use "Producir" en la lista: descuenta los ingredientes o insumos.',
                                  key: const Key('ajuste_usar_producir'),
                                  style: AppTypography.etiqueta
                                      .copyWith(color: AppColors.textoInactivo),
                                ),
                              ),
                            if (_ajusteCantidadController.text
                                    .trim()
                                    .isNotEmpty &&
                                int.tryParse(_ajusteCantidadController.text
                                        .trim()) !=
                                    null &&
                                int.parse(
                                        _ajusteCantidadController.text.trim()) >
                                    0)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.espacioChico),
                                child: Text(
                                  'Stock resultante: ${_calcularStockResultante()} ${_unidadMedida == 'UNIDAD' ? 'unidades' : _unidadMedida}',
                                  style: AppTypography.etiqueta
                                      .copyWith(color: AppColors.exito),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.espacioEstandar),
                    ],
                    if (_esEdicion && widget.productoAEditar!.esElaborado)
                      CheckboxListTile(
                        key: const Key('preparacion_base_check'),
                        contentPadding: EdgeInsets.zero,
                        value: _preparacionBase,
                        onChanged: (v) =>
                            setStateDialog(() => _preparacionBase = v ?? false),
                        title: const Text('Preparación base (no se vende)'),
                        subtitle: const Text('Ej.: ganache. No aparece en el punto de venta.'),
                      ),
                    // Estado
                    Row(
                      children: [
                        const Text('Estado:'),
                        const SizedBox(width: AppSpacing.espacioEstandar),
                        Switch(
                          value: _activo,
                          onChanged: (value) =>
                              setStateDialog(() => _activo = value),
                        ),
                        Text(_activo ? 'Activo' : 'Inactivo'),
                      ],
                    ),
                    if (_backendError != null)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.espacioEstandar),
                        child: Text(_backendError!,
                            style: AppTypography.texto
                                .copyWith(color: AppColors.error)),
                      ),
                  ],
                ),
            );
          },
        ),
      ),
    );
  }
}
