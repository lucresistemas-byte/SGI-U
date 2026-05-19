import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';

class ProductoFormDialog extends StatefulWidget {
  // ACÁ ESTÁ LA MAGIA: Ahora el modal acepta que le pasen un producto para editar
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

  // Nos fijamos si nos pasaron un producto (edición) o si vino nulo (creación)
  bool get _esEdicion => widget.productoAEditar != null;

  @override
  void initState() {
    super.initState();
    // Si es edición, llenamos los campos con los datos del producto
    _codigoController = TextEditingController(
        text: _esEdicion ? widget.productoAEditar!.codigo : '');
    _nombreController = TextEditingController(
        text: _esEdicion ? widget.productoAEditar!.nombre : '');
    _precioController = TextEditingController(
        text: _esEdicion
            ? widget.productoAEditar!.precioUnitario.toString()
            : '');
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _guardarProducto() {
    if (_formKey.currentState!.validate()) {
      final productoData = {
        // Ahora siempre mandamos todos los datos para evitar que Java nos devuelva 'null'
        'codigo': _esEdicion
            ? widget.productoAEditar!.codigo
            : _codigoController.text.trim(),
        'nombre': _nombreController.text.trim(),
        'precioUnitario': double.parse(_precioController.text.trim()),
        'stockActual': _esEdicion ? widget.productoAEditar!.stockActual : 0,
        'activo': _esEdicion ? widget.productoAEditar!.activo : true,
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
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código (SKU)'),
                enabled:
                    !_esEdicion, // Bloqueamos el código si estamos editando
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null)
                    return 'Debe ser un número válido';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _guardarProducto,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40)),
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
