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
                RadioListTile<String>(
                  title: const Text('Efectivo'),
                  value: 'EFECTIVO',
                  groupValue: state.selectedPaymentMethod,
                  onChanged: (value) {
                    context.read<PosBloc>().add(SelectPaymentMethod(value!));
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Mercado Pago'),
                  value: 'MERCADO_PAGO',
                  groupValue: state.selectedPaymentMethod,
                  onChanged: (value) {
                    context.read<PosBloc>().add(SelectPaymentMethod(value!));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}