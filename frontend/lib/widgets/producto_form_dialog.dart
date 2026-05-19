import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';

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

  bool get _esEdicion => widget.productoAEditar != null;

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
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Método para verificar si el formulario es válido en tiempo real
  bool _isFormValid() {
    final codigoValido = _codigoController.text.trim().isNotEmpty;
    final nombreValido = _nombreController.text.trim().isNotEmpty;
    final precioValido = _precioController.text.trim().isNotEmpty &&
        double.tryParse(_precioController.text.trim()) != null;
    return codigoValido && nombreValido && precioValido;
  }

  void _guardarProducto() {
    if (_formKey.currentState!.validate()) {
      final productoData = {
        'codigo': _esEdicion
            ? widget.productoAEditar!.codigo
            : _codigoController.text.trim(),
        'nombre': _nombreController.text.trim(),
        'precioUnitario': double.parse(_precioController.text.trim()),
        'stockActual': _esEdicion ? widget.productoAEditar!.stockActual : 0,
        'activo': _activo,
      };

      if (_esEdicion) {
        context
            .read<PosBloc>()
            .add(UpdateProduct(widget.productoAEditar!.codigo, productoData));
      } else {
        context.read<PosBloc>().add(CreateProduct(productoData));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          // Escuchamos cambios en los controladores para actualizar el estado del botón
          _codigoController.addListener(() => setStateDialog(() {}));
          _nombreController.addListener(() => setStateDialog(() {}));
          _precioController.addListener(() => setStateDialog(() {}));

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _codigoController,
                    decoration: const InputDecoration(labelText: 'Código (SKU)'),
                    enabled: !_esEdicion,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    decoration:
                    const InputDecoration(labelText: 'Nombre del Producto'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _precioController,
                    decoration:
                    const InputDecoration(labelText: 'Precio Unitario (\$)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (double.tryParse(value) == null)
                        return 'Debe ser un número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Estado:'),
                      const SizedBox(width: 16),
                      Switch(
                        value: _activo,
                        onChanged: (value) {
                          setStateDialog(() {
                            _activo = value;
                          });
                        },
                      ),
                      Text(_activo ? 'Activo' : 'Inactivo'),
                    ],
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
          // El botón se deshabilita si el formulario no es válido
          onPressed: _isFormValid() ? _guardarProducto : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              disabledBackgroundColor: Colors.grey.shade400),
          child: const Text('Guardar Producto', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}