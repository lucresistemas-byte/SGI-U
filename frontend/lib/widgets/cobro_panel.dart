import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../models/metodo_pago.dart';
import '../utils/numeros.dart';
import 'metodo_pago_dropdown.dart';

String _pesos(double v) => formatPesos(v);

/// Cobro del POS (D.4.1/D.4.2): una o varias líneas (método + monto) que
/// cubran el total. Un toque en un método paga todo lo que falta (venta
/// simple, tan rápida como antes). Solo el efectivo puede pasarse: la
/// diferencia es el vuelto.
class CobroPanel extends StatelessWidget {
  const CobroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final bloc = context.read<PosBloc>();
        final puedeCargar = state.cart.isNotEmpty && state.restante > 0;
        return Card(
          key: const Key('cobro_panel'),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cobro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (state.metodosPago.isEmpty)
                  const Text('No hay métodos de pago activos. Revise Configuración → Métodos de pago.',
                      key: Key('sin_metodos_pago'))
                else ...[
                  const Text('Pagar lo que falta con:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in state.metodosPago)
                        OutlinedButton(
                          key: Key('pagar_restante_${m.id}'),
                          onPressed: puedeCargar ? () => bloc.add(PagarRestante(m.id)) : null,
                          child: Text(m.nombre),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AgregarPago(metodos: state.metodosPago, habilitado: puedeCargar),
                ],
                if (state.pagos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (var i = 0; i < state.pagos.length; i++)
                    Row(
                      key: Key('linea_pago_$i'),
                      children: [
                        Expanded(child: Text(state.pagos[i].metodo.nombre)),
                        Text(_pesos(state.pagos[i].monto)),
                        IconButton(
                          key: Key('quitar_pago_$i'),
                          tooltip: 'Quitar pago',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => bloc.add(QuitarPago(i)),
                        ),
                      ],
                    ),
                ],
                const Divider(),
                Row(
                  children: [
                    const Expanded(child: Text('Pagado')),
                    Text(_pesos(state.totalPagado), key: const Key('pago_total_pagado')),
                  ],
                ),
                if (state.cart.isNotEmpty && state.restante > 0)
                  Text('Falta: ${_pesos(state.restante)}',
                      key: const Key('pago_falta'),
                      style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w600))
                else if (state.vuelto > 0)
                  Text('Vuelto: ${_pesos(state.vuelto)}',
                      key: const Key('pago_vuelto'),
                      style: const TextStyle(
                          color: Color(0xFF13894E), fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Línea de pago con monto: para pagar una parte con un método (o entregar
/// efectivo de más y ver el vuelto).
class _AgregarPago extends StatefulWidget {
  final List<MetodoPago> metodos;
  final bool habilitado;

  const _AgregarPago({required this.metodos, required this.habilitado});

  @override
  State<_AgregarPago> createState() => _AgregarPagoState();
}

class _AgregarPagoState extends State<_AgregarPago> {
  final _monto = TextEditingController();
  int? _metodoId;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _agregar() {
    final id = _metodoId ?? MetodoPagoDropdown.porDefecto(widget.metodos);
    final monto = double.tryParse(_monto.text.trim().replaceAll(',', '.'));
    if (id == null || monto == null) return;
    context.read<PosBloc>().add(AgregarPago(id, monto));
    _monto.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('pago_monto_input'),
            controller: _monto,
            enabled: widget.habilitado,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ ', isDense: true),
            onSubmitted: (_) => _agregar(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: MetodoPagoDropdown(
            key: const Key('pago_metodo_dropdown'),
            metodos: widget.metodos,
            valor: _metodoId ?? MetodoPagoDropdown.porDefecto(widget.metodos),
            etiqueta: 'Método',
            onChanged: (id) => setState(() => _metodoId = id),
          ),
        ),
        IconButton(
          key: const Key('agregar_pago_button'),
          tooltip: 'Agregar pago',
          icon: const Icon(Icons.add_circle),
          onPressed: widget.habilitado ? _agregar : null,
        ),
      ],
    );
  }
}
