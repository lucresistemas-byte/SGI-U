import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';
import '../services/ticket_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  @override
  void initState() {
    super.initState();
    // Usa el PosBloc global provisto en main.dart (evita una segunda
    // instancia desincronizada con Catálogo) y refresca el stock
    context.read<PosBloc>().add(LoadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return const PosView();
  }
}

class PosView extends StatelessWidget {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (previous, current) {
        final errorBorn = previous.errorMessage == null && current.errorMessage != null;
        final successBorn = previous.successMessage == null && current.successMessage != null;
        return errorBorn || successBorn;
      },
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
          final sale = state.completedSale;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Éxito'),
              content: Text(state.successMessage!),
              actions: [
                if (sale != null)
                  TextButton.icon(
                    onPressed: () async {
                      final pdfBytes =
                          await TicketService.generarTicket(sale: sale);
                      if (context.mounted) {
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdfBytes,
                          name: 'Ticket SGI-U',
                        );
                      }
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver ticket'),
                  ),
                TextButton(
                  onPressed: () {
                    context.read<PosBloc>().add(const ClearSuccess());
                    Navigator.pop(context);
                  },
                  child: const Text('Nueva venta'),
                ),
              ],
            ),
          );
        }
      },
      child: AppScaffold(
        title: 'Punto de Venta',
        rutaActual: '/pos',
        body: FractionallySizedBox(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Row(
            children: [
              const Expanded(flex: 7, child: LeftPanel()),
              const Expanded(flex: 3, child: RightPanel()),
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
            height: 200,
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
                        // FIX: Verificamos si la cantidad total en carrito superaría el stock
                        final currentCartQty = state.cart[product.codigo]?.cantidad ?? 0;
                        if (currentCartQty + quantity <= product.stockActual) {
                          context
                              .read<PosBloc>()
                              .add(AddToCart(product.codigo, quantity));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Stock máximo alcanzado. Solo quedan ${product.stockActual} en stock.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
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
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
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
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  _searchController.addListener(() {
                    if (_searchController.text.isEmpty)
                      setState(() => _selectedProductCode = null);
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
                  // FIX: Validamos stock al agregar por búsqueda
                  final product = state.products
                      .firstWhere((p) => p.codigo == _selectedProductCode);
                  final currentCartQty = state.cart[_selectedProductCode]?.cantidad ?? 0;

                  if (currentCartQty + quantity <= product.stockActual) {
                    context
                        .read<PosBloc>()
                        .add(AddToCart(_selectedProductCode!, quantity));
                    _searchController.clear();
                    setState(() => _selectedProductCode = null);
                    _quantityController.text = '1';
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Stock insuficiente. Quedan ${product.stockActual} unidades.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Seleccione un producto de la lista')),
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
              final item = entry.value;
              // Stock check necesita el producto actual del catálogo
              final product = state.products.firstWhere(
                (p) => p.codigo == entry.key,
                orElse: () => Product(
                    codigo: '', nombre: '', precioUnitario: 0, stockActual: 0),
              );
              return DataRow(cells: [
                DataCell(Text(item.nombre)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          int newQty = item.cantidad - 1;
                          if (newQty >= 0) {
                            context.read<PosBloc>().add(
                                UpdateCartItemQuantity(item.codigo, newQty));
                          }
                        },
                      ),
                      Text(item.cantidad.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (item.cantidad < product.stockActual) {
                            context.read<PosBloc>().add(UpdateCartItemQuantity(
                                item.codigo, item.cantidad + 1));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'No hay más stock de ${item.nombre}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                DataCell(
                    Text('\$${item.precioUnitario.toStringAsFixed(2)}')),
                DataCell(Text(
                    '\$${item.subtotal.toStringAsFixed(2)}')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      context
                          .read<PosBloc>()
                          .add(RemoveFromCart(item.codigo));
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
          PaymentMethodSelector(),
          const Spacer(),
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '\$${state.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
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
                // FIX: Validamos PRIMERO que el carrito no esté vacío
                if (state.cart.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Carrito vacío'),
                      content: const Text('Agregue productos antes de cobrar.'),
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

                // Si el carrito tiene cosas, verificamos el método de pago
                if (state.selectedPaymentMethod == null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Método de pago requerido'),
                      content:
                          const Text('Seleccione cómo va a abonar el cliente.'),
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

                // Si todo está bien, disparamos la venta al backend
                context.read<PosBloc>().add(const ConfirmSale());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdePrincipal,
                foregroundColor: AppColors.blanco,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CONFIRMAR COBRO',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                final state = context.read<PosBloc>().state;
                // Solo mostrar confirmación si hay algo que limpiar
                if (state.cart.isEmpty && state.selectedPaymentMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No hay selecciones para limpiar')),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Limpiar selección'),
                    content: const Text(
                        '¿Está seguro de que desea descartar todos los productos y el método de pago seleccionado?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<PosBloc>().add(const ClearSelection());
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.rojoEgresos),
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('LIMPIAR SELECCIÓN',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
