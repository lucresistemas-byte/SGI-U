import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item.dart';
import '../widgets/payment_method_selector.dart';
import '../models/product.dart';
class PosScreen extends StatelessWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PosBloc()..add(LoadProducts()),
      child: const PosView(),
    );
  }
}

class PosView extends StatelessWidget {
  const PosView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FractionallySizedBox(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: Row(
          children: const [
            Expanded(flex: 7, child: LeftPanel()),
            Expanded(flex: 3, child: RightPanel()),
          ],
        ),
      ),
    );
  }
}

class LeftPanel extends StatelessWidget {
  const LeftPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Barra de búsqueda + cantidad + botón Agregar
          const SearchAddBar(),
          const SizedBox(height: 16),
          // Lista horizontal de productos rápidos
          SizedBox(
            height: 120,
            child: BlocBuilder<PosBloc, PosState>(
              builder: (context, state) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      onAdd: (quantity) {
                        context.read<PosBloc>().add(AddToCart(product.codigo, quantity));
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Tabla del carrito
          const Expanded(child: CartTable()),
        ],
      ),
    );
  }
}

class SearchAddBar extends StatefulWidget {
  const SearchAddBar({Key? key}) : super(key: key);

  @override
  State<SearchAddBar> createState() => _SearchAddBarState();
}

class _SearchAddBarState extends State<SearchAddBar> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  String? _selectedProductCode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return [];
                  return state.products
                      .where((product) =>
                  product.nombre
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()) ||
                      product.codigo
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()))
                      .map((product) => product.codigo)
                      .toList();
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedProductCode = selection;
                    _searchController.text = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _searchController.addListener(() {
                    if (_searchController.text.isEmpty) setState(() => _selectedProductCode = null);
                  });
                  return TextField(
                    controller: _searchController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto (código o nombre)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Cant.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(_quantityController.text) ?? 1;
                if (quantity <= 0) return;
                if (_selectedProductCode != null) {
                  context.read<PosBloc>().add(AddToCart(_selectedProductCode!, quantity));
                  _searchController.clear();
                  setState(() => _selectedProductCode = null);
                  _quantityController.text = '1';
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione un producto de la lista')),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}

class CartTable extends StatelessWidget {
  const CartTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.cart.isEmpty) {
          return const Center(child: Text('No hay productos agregados'));
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Cantidad')),
                    DataColumn(label: Text('Precio Unit.')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('')),
                  ],
                  rows: state.cart.entries.map((entry) {
                    final product = state.products.firstWhere(
                          (p) => p.codigo == entry.key,
                      orElse: () => Product(codigo: '', nombre: '', precioUnitario: 0, stockActual: 0),
                    );
                    return DataRow(cells: [
                      DataCell(Text(product.nombre)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                int newQty = entry.value - 1;
                                if (newQty >= 0) {
                                  context.read<PosBloc>().add(UpdateCartItemQuantity(product.codigo, newQty));
                                }
                              },
                            ),
                            Text(entry.value.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                context.read<PosBloc>().add(UpdateCartItemQuantity(product.codigo, entry.value + 1));
                              },
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text('\$${product.precioUnitario.toStringAsFixed(2)}')),
                      DataCell(Text('\$${(product.precioUnitario * entry.value).toStringAsFixed(2)}')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            context.read<PosBloc>().add(RemoveFromCart(product.codigo));
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class RightPanel extends StatelessWidget {
  const RightPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Selector de método de pago arriba a la derecha
          const PaymentMethodSelector(),
          const Spacer(),
          // Total de la venta
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '\$${state.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Botón Confirmar Cobro (grande, esquina inferior derecha)
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton(
              onPressed: () {
                final state = context.read<PosBloc>().state;
                if (state.selectedPaymentMethod == null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Error'),
                      content: const Text('Seleccione un método de pago'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                if (state.cart.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Carrito vacío'),
                      content: const Text('Agregue productos antes de cobrar'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Funcionalidad en desarrollo'),
                    content: const Text('Esta acción simulará el cobro en futuras iteraciones.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CONFIRMAR COBRO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}