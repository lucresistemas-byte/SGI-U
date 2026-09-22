import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Text('Método de pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                RadioGroup<String>(
                  groupValue: state.selectedPaymentMethod,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<PosBloc>().add(SelectPaymentMethod(value));
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Efectivo'),
                        value: 'EFECTIVO',
                      ),
                      RadioListTile<String>(
                        title: const Text('Mercado Pago'),
                        value: 'MERCADO_PAGO',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}