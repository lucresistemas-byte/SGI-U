import 'package:flutter/material.dart';
import '../models/metodo_pago.dart';

/// Método de pago a elegir entre los activos (en el orden de Configuración).
class MetodoPagoDropdown extends StatelessWidget {
  final List<MetodoPago> metodos;
  final int? valor;
  final ValueChanged<int> onChanged;
  final String etiqueta;

  const MetodoPagoDropdown({
    super.key,
    required this.metodos,
    required this.valor,
    required this.onChanged,
    this.etiqueta = 'Método de pago',
  });

  /// Por defecto, Efectivo (el fijo); si no está, el primero.
  static int? porDefecto(List<MetodoPago> metodos) {
    if (metodos.isEmpty) return null;
    return metodos.firstWhere((m) => m.esEfectivo, orElse: () => metodos.first).id;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      // La key recrea el campo cuando llega la lista (initialValue se lee una vez).
      key: ValueKey('metodo_pago_${metodos.length}_$valor'),
      initialValue: metodos.any((m) => m.id == valor) ? valor : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: etiqueta),
      hint: Text(metodos.isEmpty ? 'Cargando métodos...' : 'Elegir método'),
      items: [
        for (final m in metodos) DropdownMenuItem(value: m.id, child: Text(m.nombre)),
      ],
      // Sin lista (no se pudo cargar) no se bloquea: el backend usa Efectivo
      // donde el método es opcional.
      validator: (v) => v == null && metodos.isNotEmpty ? 'Elija el método de pago' : null,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
