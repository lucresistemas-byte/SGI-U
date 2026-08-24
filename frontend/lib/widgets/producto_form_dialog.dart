import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';

class ProductoFormDialog extends StatefulWidget {
  final Product? productoAEditar;
  const ProductoFormDialog({super.key, this.productoAEditar});

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late bool _activo;

  // Stock inicial (solo creación)
  late TextEditingController _stockInicialController;
  // Controles de ajuste (solo edición)
  late TextEditingController _ajusteCantidadController;
  String _ajusteTipo = 'sumar';
  int _stockActualMostrado = 0;

  bool get _esEdicion => widget.productoAEditar != null;
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(
        text: _esEdicion ? widget.productoAEditar!.codigo : '');
    _nombreController = TextEditingController(
        text: _esEdicion ? widget.productoAEditar!.nombre : '');
    _precioController = TextEditingController(
        text: _esEdicion
            ? widget.productoAEditar!.precioUnitario.toString()
            : '');
    _activo = _esEdicion ? widget.productoAEditar!.activo : true;
    _stockInicialController = TextEditingController(text: '0');
    _ajusteCantidadController = TextEditingController(text: '0');
    if (_esEdicion) {
      _stockActualMostrado = widget.productoAEditar!.stockActual;
    }

    // Listeners para actualizar estado del diálogo cuando cambian campos
    _codigoController.addListener(() => setState(() {}));
    _nombreController.addListener(() => setState(() {}));
    _precioController.addListener(() => setState(() {}));
    _stockInicialController.addListener(() => setState(() {}));
    _ajusteCantidadController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _stockInicialController.dispose();
    _ajusteCantidadController.dispose();
    super.dispose();
  }

  bool _isPrecioValido() {
    final precioText = _precioController.text.trim();
    if (precioText.isEmpty) return false;
    // Aceptar coma como separador decimal
    final normalized = precioText.replaceAll(',', '.');
    final precio = double.tryParse(normalized);
    return precio != null && precio > 0;
  }

  bool _isStockInicialValido() {
    if (_esEdicion) return true;
    final stockText = _stockInicialController.text.trim();
    if (stockText.isEmpty) return false;
    final stock = int.tryParse(stockText);
    return stock != null && stock >= 0;
  }

  bool _isAjusteValido() {
    if (!_esEdicion) return true;
    final cantidad = int.tryParse(_ajusteCantidadController.text.trim()) ?? 0;
    if (cantidad <= 0) return false;
    if (_ajusteTipo == 'restar' && cantidad > _stockActualMostrado)
      return false;
    return true;
  }

  bool _isFormValid() {
    final nombreValido = _nombreController.text.trim().isNotEmpty;
    final codigoValido = _codigoController.text.trim().isNotEmpty;
    final precioValido = _isPrecioValido();
    final stockInicialValido = _isStockInicialValido();
    final ajusteValido = _isAjusteValido();
    return nombreValido &&
        codigoValido &&
        precioValido &&
        stockInicialValido &&
        ajusteValido;
  }

  Map<String, dynamic> _buildProductData() {
    final data = {
      'codigo': _esEdicion
          ? widget.productoAEditar!.codigo
          : _codigoController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'precioUnitario': double.parse(
          _precioController.text.trim().replaceAll(',', '.')), // aceptar coma
      'activo': _activo,
    };

    if (!_esEdicion) {
      data['stockActual'] = int.parse(_stockInicialController.text.trim());
    } else {
      final cantidadAjuste =
          int.tryParse(_ajusteCantidadController.text.trim()) ?? 0;
      if (cantidadAjuste > 0) {
        int nuevoStock = _calcularStockResultante();
        data['stockActual'] = nuevoStock;
      } else {
        data['stockActual'] = _stockActualMostrado;
      }
    }
    return data;
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
          ));
    } else {
      context.read<PosBloc>().add(CreateProduct(productoData));
    }
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
      child: AlertDialog(
        title: Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            // No agregamos listeners aquí (se agregan en initState)

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Código
                    TextFormField(
                      controller: _codigoController,
                      decoration:
                          const InputDecoration(labelText: 'Código (SKU)'),
                      enabled: !_esEdicion,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Producto'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    // Precio
                    TextFormField(
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario (\$)',
                        hintText: 'Debe ser mayor a 0',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'El precio es obligatorio.';
                        final precio = double.tryParse(value);
                        if (precio == null)
                          return 'Ingrese un valor numérico válido.';
                        if (precio <= 0) {
                          return 'El precio debe ser mayor a \$0.';
                        }
                        if (value.contains('.') &&
                            value.split('.')[1].length > 2) {
                          return 'Máximo 2 decimales permitidos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                          if (value == null || value.isEmpty)
                            return 'Requerido';
                          final stock = int.tryParse(value);
                          if (stock == null) return 'Debe ser un número entero';
                          if (stock < 0)
                            return 'El stock no puede ser negativo';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Ajuste de stock (edición)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stock actual: $_stockActualMostrado unidades',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _ajusteTipo,
                                    decoration: const InputDecoration(
                                        labelText: 'Acción'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'sumar',
                                          child: Text('Sumar stock')),
                                      DropdownMenuItem(
                                          value: 'restar',
                                          child: Text('Restar stock')),
                                    ],
                                    onChanged: (value) {
                                      setStateDialog(
                                          () => _ajusteTipo = value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _ajusteCantidadController,
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                      hintText: '0',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return null;
                                      final cant = int.tryParse(value);
                                      if (cant == null) return 'Número entero';
                                      if (cant <= 0)
                                        return 'Debe ser mayor a 0';
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
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Stock resultante: ${_calcularStockResultante()} unidades',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.green),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Estado
                    Row(
                      children: [
                        const Text('Estado:'),
                        const SizedBox(width: 16),
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
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_backendError!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isFormValid() ? _guardarProducto : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: const Text('Guardar Producto',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
