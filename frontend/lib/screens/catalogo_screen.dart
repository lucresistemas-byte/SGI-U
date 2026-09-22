import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../widgets/producto_form_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // Variables para la paginación y búsqueda
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    context.read<PosBloc>().add(const LoadProducts());

    // Si el usuario escribe en el buscador, redibujamos la pantalla y volvemos a la página 1
    _searchController.addListener(() {
      setState(() {
        _currentPage = 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.grisVerdeClaro : AppColors.grisInformativo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: isActive ? AppColors.verdeActivo : AppColors.grisInactivo,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Productos',
      rutaActual: '/catalogo',
      body: BlocListener<PosBloc, PosState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red.shade800),
            );
            context.read<PosBloc>().add(const ClearError());
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.verdeTeal),
            );
            context.read<PosBloc>().add(const ClearSuccess());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Productos',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ProductoFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Agregar Nuevo Producto',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- BUSCADOR Y CHIPS DE CATEGORÍA ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto...',
                        hintStyle: TextStyle(color: Colors.grey),
                        suffixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<PosBloc, PosState>(
                      builder: (context, state) {
                        if (state.availableCategories.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final categories = ['Todas', ...state.availableCategories];
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((cat) {
                              final isSelected =
                                  (state.selectedCategory == null && cat == 'Todas') ||
                                      state.selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  key: ValueKey('catalogo_category_chip_$cat'),
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: AppColors.verdeTeal.withValues(alpha: 0.2),
                                  checkmarkColor: AppColors.verdeTeal,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.verdeTeal : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  onSelected: (selected) {
                                    final target = (selected && cat != 'Todas') ? cat : null;
                                    setState(() {
                                      _currentPage = 1;
                                    });
                                    context.read<PosBloc>().add(FilterByCategoryEvent(target));
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- CAJA BLANCA (TABLA + PAGINACIÓN) ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10)
                    ],
                  ),
                  child: BlocBuilder<PosBloc, PosState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF004D40)));
                      }

                      // 1. Filtrar los productos por categoría activa y búsqueda
                      final String query =
                          _searchController.text.toLowerCase();
                      final List<Product> filteredProducts =
                          state.filteredProducts.where((p) {
                        return p.nombre.toLowerCase().contains(query) ||
                            p.codigo.toLowerCase().contains(query);
                      }).toList();

                      // 2. Calcular paginación
                      int totalPages =
                          (filteredProducts.length / _itemsPerPage)
                              .ceil();
                      if (totalPages == 0) totalPages = 1;
                      if (_currentPage > totalPages) {
                        _currentPage = totalPages;
                      }

                      // 3. Extraer solo los 10 productos de la página actual
                      final List<Product> paginatedProducts =
                          filteredProducts
                              .skip((_currentPage - 1) * _itemsPerPage)
                              .take(_itemsPerPage)
                              .toList();

                      return Column(
                        children: [
                          // TABLA
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        headingTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B)),
                                        dataRowMaxHeight: 65,
                                        columns: const [
                                          DataColumn(label: Text('Código ↓')),
                                          DataColumn(
                                              label:
                                                  Text('Nombre del Producto')),
                                          DataColumn(label: Text('Categoría')),
                                          DataColumn(
                                              label: Text('Precio Unit. (\$)')),
                                          DataColumn(label: Text('Stock')),
                                          DataColumn(label: Text('Estado')),
                                          DataColumn(label: Text('Acciones')),
                                        ],
                                        rows: paginatedProducts.map((producto) {
                                          return DataRow(cells: [
                                            DataCell(Text(producto.codigo,
                                                style: const TextStyle(
                                                    color: Color(0xFF475569)))),
                                            DataCell(Text(producto.nombre,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1E293B)))),
                                            DataCell(Text(producto.categoria ?? '-',
                                                style: const TextStyle(
                                                    color: Color(0xFF475569)))),
                                            DataCell(Text(
                                                '\$${producto.precioUnitario.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    color: Color(0xFF475569)))),
                                             DataCell(Text(
                                                 '${producto.stockActual} ${producto.unidadMedida ?? 'UNIDAD'}',
                                                 style: const TextStyle(
                                                     color: Color(0xFF475569)))),
                                            DataCell(
                                                _buildBadge(producto.activo)),
                                            DataCell(Row(
                                              children: [
                                                // BOTÓN EDITAR
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Color(0xFF004D40),
                                                      size: 20),
                                                  onPressed: () {
                                                    // ABRE EL MODAL DE EDICIÓN
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          ProductoFormDialog(
                                                              productoAEditar:
                                                                  producto),
                                                    );
                                                  },
                                                ),
                                                // BOTÓN ARCHIVAR/DESARCHIVAR
                                                IconButton(
                                                  icon: Icon(
                                                      producto.activo
                                                          ? Icons.delete_outline
                                                          : Icons
                                                              .restore_from_trash,
                                                      color: const Color(
                                                          0xFF004D40),
                                                      size: 20),
                                                  onPressed: () {
                                                    context
                                                        .read<PosBloc>()
                                                        .add(UpdateProduct(
                                                            producto.codigo, {
                                                          'codigo': producto
                                                              .codigo, // AGREGADO
                                                          'nombre':
                                                              producto.nombre,
                                                          'precioUnitario':
                                                              producto
                                                                  .precioUnitario,
                                                          'stockActual': producto
                                                              .stockActual, // ¡EL SALVAVIDAS!
                                                          'activo':
                                                              !producto.activo,
                                                        }));
                                                  },
                                                ),
                                              ],
                                            )),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // FOOTER (PAGINACIÓN)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey.shade200))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () =>
                                          setState(() => _currentPage--)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.verdeTeal,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text('$_currentPage',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < totalPages
                                      ? () =>
                                          setState(() => _currentPage++)
                                      : null,
                                ),
                                const SizedBox(width: 24),
                                Text(
                                    'Página $_currentPage de $totalPages',
                                    style: const TextStyle(
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
