import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../models/product.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PosBloc()..add(LoadProducts()),
      child: const PosView(),
    );
  }
}

class PosView extends StatelessWidget {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () {
                    context.read<PosBloc>().add(const ClearError());
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        if (state.successMessage != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Éxito'),
              content: Text(state.successMessage!),
              actions: [
                TextButton(
                  onPressed: () {
                    context.read<PosBloc>().add(const ClearSuccess());
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        body: FractionallySizedBox(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Row(
            children: [
              Expanded(flex: 7, child: LeftPanel()),
              Expanded(flex: 3, child: RightPanel()),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== PANEL IZQUIERDO ==========
class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SearchAddBar(),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BlocBuilder<PosBloc, PosState>(
              builder: (context, state) {
                if (state.isLoading && state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
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
          const Expanded(child: CartTable()),
        ],
      ),
    );
  }
}

// Barra de búsqueda + cantidad + botón Agregar
class SearchAddBar extends StatefulWidget {
  const SearchAddBar({super.key});

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

// Tabla del carrito
class CartTable extends StatelessWidget {
  const CartTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.cart.isEmpty) {
          return const Center(child: Text('No hay productos agregados'));
        }
        return SingleChildScrollView(
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
        );
      },
    );
  }
}

// ========== PANEL DERECHO ==========
class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const PaymentMethodSelector(),
          const Spacer(),
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
                context.read<PosBloc>().add(const ConfirmSale());
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

// ========== WIDGETS AUXILIARES ==========
class ProductCard extends StatelessWidget {
  final Product product;
  final Function(int quantity) onAdd;

  const ProductCard({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => onAdd(1),
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory, size: 40),
              const SizedBox(height: 8),
              Text(product.nombre, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('\$${product.precioUnitario.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key});

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