import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';

class MovimientoFormDialog extends StatefulWidget {
  const MovimientoFormDialog({Key? key}) : super(key: key);

  @override
  State<MovimientoFormDialog> createState() => _MovimientoFormDialogState();
}

class _MovimientoFormDialogState extends State<MovimientoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'Ingreso';
  String _categoria = 'Venta';
  String _metodoPago = 'Efectivo';
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  final List<String> _tipos = ['Ingreso', 'Egreso'];
  final List<String> _categorias = ['Venta', 'Compra', 'Gasto', 'Retiro', 'Otro'];
  final List<String> _metodosPago = ['Efectivo', 'Transferencia', 'Tarjeta'];

  bool _isFormValid() {
    final montoText = _montoController.text.trim();
    final monto = double.tryParse(montoText);
    return _descripcionController.text.trim().isNotEmpty &&
        montoText.isNotEmpty &&
        monto != null &&
        monto > 0;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final monto = double.parse(_montoController.text.trim());
    final montoFinal = _tipo == 'Ingreso' ? monto : -monto;
    context.read<FinanzasBloc>().add(CrearMovimiento(
      tipo: _tipo,
      monto: montoFinal,
      metodoPago: _metodoPago,
      categoria: _categoria,
      descripcion: _descripcionController.text.trim(),
    ));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Nuevo Movimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: _tipos.map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _tipo = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Categoría
                  DropdownButtonFormField<String>(
                    value: _categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: _categorias.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _categoria = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Método de pago
                  DropdownButtonFormField<String>(
                    value: _metodoPago,
                    decoration: const InputDecoration(
                      labelText: 'Método de Pago',
                      border: OutlineInputBorder(),
                    ),
                    items: _metodosPago.map((met) {
                      return DropdownMenuItem(value: met, child: Text(met));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _metodoPago = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Monto
                  TextFormField(
                    controller: _montoController,
                    decoration: const InputDecoration(
                      labelText: 'Monto (\$)', // El \$ se escapa
                      hintText: 'Ingrese un valor positivo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El monto es obligatorio';
                      }
                      final monto = double.tryParse(value);
                      if (monto == null) {
                        return 'Ingrese un número válido';
                      }
                      if (monto <= 0) {
                        return 'El monto debe ser mayor a cero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Motivo o detalle del movimiento',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Color(0xFF006B3D)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isFormValid() ? _guardar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}