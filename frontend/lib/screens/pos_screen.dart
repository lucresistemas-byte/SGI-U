import 'package:flutter/material.dart';
import '../utils/numeros.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevations.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/product_card.dart';
import '../widgets/cobro_panel.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_button.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/estado_seccion.dart';
import '../services/ticket_service.dart';
import '../widgets/cargando_diferido.dart';

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
    context.read<PosBloc>().add(const LoadProducts());
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
            builder: (_) => AppDialog(
              titulo: 'Error',
              tamano: TamanoDialogo.chico,
              acciones: [
                AppButton.primary(
                  onPressed: () {
                    context.read<PosBloc>().add(const ClearError());
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
              child: Text(state.errorMessage!),
            ),
          );
        }
        if (state.successMessage != null) {
          final sale = state.completedSale;
          showDialog(
            context: context,
            builder: (_) => AppDialog(
              titulo: 'Éxito',
              tamano: TamanoDialogo.chico,
              acciones: [
                if (sale != null)
                  AppButton.ghost(
                    onPressed: () async {
                      try {
                        final pdfBytes =
                            await TicketService.generarTicket(sale: sale);
                        if (context.mounted) {
                          await Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: 'ticket_sgiu.pdf',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackBar.error(context, 'Error al generar ticket: $e');
                        }
                      }
                    },
                    icono: Icons.receipt_long,
                    child: const Text('Ver ticket'),
                  ),
                AppButton.primary(
                  onPressed: () {
                    context.read<PosBloc>().add(const ClearSuccess());
                    Navigator.pop(context);
                  },
                  child: const Text('Nueva venta'),
                ),
              ],
              child: Text(state.successMessage!),
            ),
          );
        }
      },
      child: const AppScaffold(
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
      padding: const EdgeInsets.all(AppSpacing.espacioEstandar),
      child: Column(
        children: [
          const SearchAddBar(),
          const SizedBox(height: AppSpacing.espacioMedio),
          const PosCategoryFilter(),
          const SizedBox(height: AppSpacing.espacioMedio),
          SizedBox(
            height: 200,
            child: BlocBuilder<PosBloc, PosState>(
              builder: (context, state) {
                if (state.isLoading && state.products.isEmpty) {
                  return const CargandoDiferido();
                }
                // El POS muestra solo lo vendible (no preparaciones base ni inactivos).
                final displayProducts = state.filteredVendibles;
                if (displayProducts.isEmpty) {
                  return EmptyState(
                    icono: Icons.search_off,
                    mensaje: state.selectedCategory != null
                        ? 'No hay productos en la categoría "${state.selectedCategory}"'
                        : 'No se encontraron productos',
                  );
                }
                return ListView.builder(
                  key: ValueKey('pos_list_${state.selectedCategory ?? 'all'}_${state.searchQuery}'),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayProducts[index];
                    return ProductCard(
                      key: ValueKey('pos_product_card_${product.codigo}'),
                      product: product,
                      onAdd: (quantity) {
                        // FIX: Verificamos si la cantidad total en carrito superaría el stock
                        final currentCartQty = state.cart[product.codigo]?.cantidad ?? 0;
                        if (currentCartQty + quantity <= product.stockActual) {
                          context
                              .read<PosBloc>()
                              .add(AddToCart(product.codigo, quantity));
                        } else {
                          AppSnackBar.error(context,
                              'Stock máximo alcanzado. Solo quedan ${product.stockActual} en stock.');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          const Expanded(child: CartTable()),
        ],
      ),
    );
  }
}

// Filtro de categorías horizontal para POS
class PosCategoryFilter extends StatelessWidget {
  const PosCategoryFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.availableCategoriesVendibles.isEmpty) {
          return const SizedBox.shrink();
        }
        final categories = ['Todas', ...state.availableCategoriesVendibles];
        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.espacioChico),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected =
                  (state.selectedCategory == null && cat == 'Todas') ||
                      state.selectedCategory == cat;
              return FilterChip(
                key: ValueKey('pos_category_chip_$cat'),
                label: Text(cat),
                selected: isSelected,
                selectedColor: AppColors.seleccionFondo,
                checkmarkColor: AppColors.marcaActiva,
                labelStyle: AppTypography.etiqueta.copyWith(
                  color: isSelected ? AppColors.marcaActiva : AppColors.textoPrincipal,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  final target = (selected && cat != 'Todas') ? cat : null;
                  context.read<PosBloc>().add(FilterByCategoryEvent(target));
                },
              );
            },
          ),
        );
      },
    );
  }
}

// Barra de búsqueda de productos (Punto 1: sin campo de cantidad ni botón Agregar)
class SearchAddBar extends StatefulWidget {
  const SearchAddBar({super.key});

  @override
  State<SearchAddBar> createState() => _SearchAddBarState();
}

class _SearchAddBarState extends State<SearchAddBar> {
  TextEditingController? _searchController;

  void _addProductToCart(BuildContext context, PosState state, Product product) {
    final currentCartQty = state.cart[product.codigo]?.cantidad ?? 0;
    if (currentCartQty + 1 <= product.stockActual) {
      context.read<PosBloc>().add(AddToCart(product.codigo, 1));
      _searchController?.clear();
      context.read<PosBloc>().add(const SearchProductsEvent(''));
    } else {
      AppSnackBar.error(context,
          'Stock insuficiente. Quedan ${textoStock(product.stockActual, product.unidadStock)} de "${product.nombre}".');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Autocomplete<Product>(
          displayStringForOption: (Product product) =>
              '${product.codigo} - ${product.nombre}',
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return const [];
            final text = textEditingValue.text.toLowerCase();
            return state.vendibles
                .where((product) =>
                    product.nombre.toLowerCase().contains(text) ||
                    product.codigo.toLowerCase().contains(text))
                .toList();
          },
          onSelected: (Product product) {
            _addProductToCart(context, state, product);
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: AppElevations.sombraModal,
                borderRadius: AppRadii.bordeChico,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 250, maxWidth: 450),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Product option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${option.codigo} • Stock: ${textoStock(option.stockActual, option.unidadStock)} • ${formatPesos(option.precioUnitario)}',
                          style: AppTypography.etiqueta.copyWith(
                            color: option.stockActual <= 0
                                ? AppColors.error
                                : AppColors.textoTerciario,
                          ),
                        ),
                        trailing: const Icon(Icons.add_shopping_cart,
                            size: 20, color: AppColors.marcaActiva),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) {
            _searchController = controller;
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, val, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto (código o nombre)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: val.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              controller.clear();
                              context
                                  .read<PosBloc>()
                                  .add(const SearchProductsEvent(''));
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    context
                        .read<PosBloc>()
                        .add(SearchProductsEvent(text.trim()));
                  },
                  onSubmitted: (value) {
                    final query = value.trim();
                    if (query.isEmpty) return;
                    final exactMatch = state.vendibles
                        .where((p) =>
                            p.codigo.toLowerCase() == query.toLowerCase() ||
                            p.nombre.toLowerCase() == query.toLowerCase())
                        .firstOrNull;
                    if (exactMatch != null) {
                      _addProductToCart(context, state, exactMatch);
                    } else {
                      onFieldSubmitted();
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// Control de cantidad en carrito: [-] [caja editable directa] [+] (Punto 1)
class CartQuantityInput extends StatefulWidget {
  final CartItem item;
  final Product product;

  const CartQuantityInput({
    super.key,
    required this.item,
    required this.product,
  });

  @override
  State<CartQuantityInput> createState() => _CartQuantityInputState();
}

class _CartQuantityInputState extends State<CartQuantityInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  int? _lastAppliedQty;

  @override
  void initState() {
    super.initState();
    _lastAppliedQty = widget.item.cantidad;
    _controller = TextEditingController(text: widget.item.cantidad.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyQuantity(_controller.text);
    }
  }

  @override
  void didUpdateWidget(CartQuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.cantidad != oldWidget.item.cantidad) {
      _lastAppliedQty = widget.item.cantidad;
      if (_controller.text != widget.item.cantidad.toString()) {
        _controller.text = widget.item.cantidad.toString();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applyQuantity(String value) {
    final newQty = int.tryParse(value.trim());
    if (newQty == null || newQty <= 0) {
      // Si el valor ingresado es vacío o inválido (<= 0), restauramos la cantidad actual
      _controller.text = widget.item.cantidad.toString();
      return;
    }

    if (newQty > widget.product.stockActual) {
      AppSnackBar.error(context,
          'Stock máximo para "${widget.item.nombre}" es ${textoStock(widget.product.stockActual, widget.product.unidadStock)}.');
      _controller.text = widget.product.stockActual.toString();
      if (_lastAppliedQty != widget.product.stockActual) {
        _lastAppliedQty = widget.product.stockActual;
        context.read<PosBloc>().add(
            UpdateCartItemQuantity(widget.item.codigo, widget.product.stockActual));
      }
      return;
    }

    if (newQty != _lastAppliedQty) {
      _lastAppliedQty = newQty;
      context
          .read<PosBloc>()
          .add(UpdateCartItemQuantity(widget.item.codigo, newQty));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          splashRadius: 16,
          tooltip: 'Restar unidad',
          onPressed: () {
            final newQty = widget.item.cantidad - 1;
            if (newQty >= 0) {
              context
                  .read<PosBloc>()
                  .add(UpdateCartItemQuantity(widget.item.codigo, newQty));
            }
          },
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 44,
          height: 32,
          child: TextField(
            key: ValueKey('cart_qty_field_${widget.item.codigo}'),
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTypography.etiqueta.copyWith(fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              contentPadding: AppSpacing.campoCompacto,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: AppRadii.bordeControl,
                borderSide: BorderSide(color: AppColors.bordeSuave),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.bordeControl,
                borderSide:
                    BorderSide(color: AppColors.marcaActiva, width: 1.5),
              ),
            ),
            onChanged: (val) {
              final qty = int.tryParse(val.trim());
              if (qty != null &&
                  qty > 0 &&
                  qty <= widget.product.stockActual &&
                  qty != _lastAppliedQty) {
                _lastAppliedQty = qty;
                context
                    .read<PosBloc>()
                    .add(UpdateCartItemQuantity(widget.item.codigo, qty));
              }
            },
            onSubmitted: _applyQuantity,
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          icon: const Icon(Icons.add, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          splashRadius: 16,
          tooltip: 'Sumar unidad',
          onPressed: () {
            if (widget.item.cantidad < widget.product.stockActual) {
              context.read<PosBloc>().add(UpdateCartItemQuantity(
                  widget.item.codigo, widget.item.cantidad + 1));
            } else {
              AppSnackBar.error(context,
                  'Stock máximo alcanzado. Solo quedan ${widget.product.stockActual} de ${widget.item.nombre}');
            }
          },
        ),
      ],
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
          return const EmptyState(
            icono: Icons.shopping_cart_outlined,
            mensaje: 'No hay productos agregados',
          );
        }
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: AppSpacing.espacioEstandar,
              horizontalMargin: AppSpacing.espacioMedio,
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
                    CartQuantityInput(
                      key: ValueKey('cart_qty_${item.codigo}'),
                      item: item,
                      product: product,
                    ),
                  ),
                  DataCell(
                      Text(formatPesos(item.precioUnitario))),
                  DataCell(
                      Text(formatPesos(item.subtotal))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
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
      color: AppColors.fondoApp,
      padding: const EdgeInsets.all(AppSpacing.espacioEstandar),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: SingleChildScrollView(child: CobroPanel())),
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.espacioEstandar),
                  child: Column(
                    children: [
                      Text('Total',
                          style: AppTypography.subtitulo.copyWith(
                              color: AppColors.textoPrincipal)),
                      const SizedBox(height: AppSpacing.espacioChico),
                      Text(
                        formatPesos(state.totalAmount),
                        style: AppTypography.numeroKpi
                            .copyWith(color: AppColors.textoPrincipal),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          // Se habilita solo cuando los pagos cubren el total.
          BlocBuilder<PosBloc, PosState>(
            buildWhen: (a, b) => a.cobroCubierto != b.cobroCubierto || a.isProcessing != b.isProcessing,
            builder: (context, state) => SizedBox(
              width: double.infinity,
              height: 70,
              child: AppButton.primary(
                key: const Key('confirmar_cobro_button'),
                onPressed: state.cobroCubierto && !state.isProcessing
                    ? () => context.read<PosBloc>().add(const ConfirmSale())
                    : null,
                child: const Text('CONFIRMAR COBRO'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.espacioMedio),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButton.secondary(
              onPressed: () {
                final state = context.read<PosBloc>().state;
                // Solo mostrar confirmación si hay algo que limpiar
                if (state.cart.isEmpty && state.pagos.isEmpty) {
                  AppSnackBar.info(context, 'No hay selecciones para limpiar');
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => AppDialog(
                    titulo: 'Limpiar selección',
                    tamano: TamanoDialogo.medio,
                    acciones: [
                      AppButton.ghost(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      AppButton.danger(
                        onPressed: () {
                          context.read<PosBloc>().add(const ClearSelection());
                          Navigator.pop(context);
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                    child: const Text(
                        '¿Está seguro de que desea descartar todos los productos y los pagos cargados?'),
                  ),
                );
              },
              child: const Text('LIMPIAR SELECCIÓN'),
            ),
          ),
        ],
      ),
    );
  }
}
