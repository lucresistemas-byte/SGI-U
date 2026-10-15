import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../widgets/producto_form_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';
import '../widgets/cargando_diferido.dart';
import '../services/api_service.dart';
import '../utils/numeros.dart';
import 'historial_precios_view.dart';
import '../models/stock.dart';
import '../widgets/produccion_dialog.dart';
import '../widgets/stock_historial_dialog.dart';
import '../widgets/tabla_ajustada.dart';

class CatalogoScreen extends StatefulWidget {
  /// Para el historial de precios (inyectable en los tests).
  final ApiService? apiService;

  const CatalogoScreen({super.key, this.apiService});

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

  /// Tipo de artículo: el comportamiento depende de él, no de la categoría.
  Widget _buildTipo(Product producto) {
    final etiqueta = producto.esPreparacionBase
        ? 'Preparación base'
        : switch (producto.tipo) {
            'ELABORADO' => 'Elaborado',
            'REVENTA' => 'Reventa',
            'MATERIA_PRIMA' => 'Materia prima',
            'INSUMO' => 'Insumo',
            'REVENTA_MATERIA_PRIMA' => 'Reventa + materia prima',
            'PAQUETE' => 'Paquete',
            _ => producto.tipo,
          };
    return Container(
      key: Key('tipo_${producto.codigo}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(etiqueta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
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

  /// Productos: dos pestañas, la lista y el historial de precios.
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Material(
              color: Colors.white,
              child: TabBar(
                key: Key('tabs_productos'),
                labelColor: AppColors.verdeTeal,
                indicatorColor: AppColors.verdeTeal,
                tabs: [
                  Tab(key: Key('tab_productos'), text: 'Productos'),
                  Tab(key: Key('tab_historial_precios'), text: 'Historial de precios'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_productos(context), HistorialPreciosView(apiService: widget.apiService)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stock en su unidad (negativo en rojo) y, si se produce, cuántos se
  /// pueden producir con el stock de sus componentes.
  Widget _stock(Product producto) {
    final negativo = producto.stockActual < 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textoStock(producto.stockActual, producto.unidadStock),
          key: Key('stock_${producto.codigo}'),
          style: TextStyle(
              color: negativo ? Colors.red.shade700 : const Color(0xFF475569),
              fontWeight: negativo ? FontWeight.bold : FontWeight.normal),
        ),
        if (producto.seProduce && producto.puedeProducir != null)
          Text('Puedo producir hasta ${producto.puedeProducir}',
              key: Key('puede_producir_${producto.codigo}'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  /// Producir: dialogo en dos pasos (faltantes → confirmar). Después recarga
  /// el catálogo y avisa qué se consumió.
  Future<void> _producir(Product producto) async {
    final resultado = await showDialog<ResultadoProduccion>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProduccionDialog(producto: producto, apiService: widget.apiService),
    );
    if (resultado == null || !mounted) return;
    context.read<PosBloc>().add(const LoadProducts());
    final consumos = resultado.consumos.map((c) => '${c.nombre} ${c.cantidadTexto}').join(', ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: resultado.conFaltantes ? Colors.orange.shade800 : AppColors.verdeTeal,
      content: Text('Se produjeron ${formatDecimal(resultado.cantidad)} ${resultado.nombre}'
          '${resultado.conFaltantes ? ' (con faltantes: hay stock negativo)' : ''}. Consumo: $consumos.'),
    ));
  }

  Widget _productos(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
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
                        return const CargandoDiferido(
                            color: Color(0xFF004D40));
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
                            child: TablaAjustada(
                              tabla: DataTable(
                                key: const Key('tabla_productos'),
                                columnSpacing: 16,
                                horizontalMargin: 16,
                                headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B)),
                                dataRowMaxHeight: double.infinity,
                                columns: const [
                                  DataColumn(columnWidth: columnaAjustable, label: Text('Código ↓')),
                                  DataColumn(
                                      columnWidth: columnaFlexible,
                                      label:
                                          Text('Nombre del Producto')),
                                  DataColumn(columnWidth: columnaAjustable, label: Text('Tipo')),
                                  DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Categoría')),
                                  DataColumn(
                                      columnWidth: columnaAjustable, label: Text('Precio Unit.')),
                                  DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia')),
                                  DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Stock')),
                                  DataColumn(columnWidth: columnaAjustable, label: Text('Estado')),
                                  DataColumn(columnWidth: columnaAjustable, label: Text('Acciones')),
                                ],
                                rows: paginatedProducts.map((producto) {
                                  return DataRow(cells: [
                                    DataCell(Text(producto.codigo,
                                        style: const TextStyle(
                                            color: Color(0xFF475569)))),
                                    DataCell(Text(producto.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1E293B)))),
                                    DataCell(_buildTipo(producto)),
                                    DataCell(Text(producto.categoria ?? '-',
                                        maxLines: 2,
                                        style: const TextStyle(
                                            color: Color(0xFF475569)))),
                                    DataCell(Text(
                                        '${formatPesos(producto.precioUnitario)}'
                                        '${producto.precioManual ? '\n(a mano)' : ''}',
                                        key: Key('precio_${producto.codigo}'),
                                        style: const TextStyle(
                                            color: Color(0xFF475569)))),
                                    // Ganancia por unidad en $ y en %.
                                    DataCell(Text(
                                        producto.gananciaPesos == null
                                            ? '—'
                                            : '${formatPesos(producto.gananciaPesos!)}'
                                                '${producto.porcentajeReal != null ? '\n${formatDecimal(producto.porcentajeReal!, decimales: 1)} %' : ''}',
                                        key: Key('ganancia_${producto.codigo}'),
                                        style: const TextStyle(
                                            color: Color(0xFF15803D),
                                            fontWeight: FontWeight.w600))),
                                    DataCell(_stock(producto)),
                                    DataCell(
                                        _buildBadge(producto.activo)),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // BOTÓN EDITAR (la reventa + materia
                                        // prima se edita en Materia Prima).
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          key: Key('editar_producto_${producto.codigo}'),
                                          tooltip: producto.esReventaMateriaPrima
                                              ? 'Se edita en Materia Prima'
                                              : producto.esPaquete
                                                  ? 'Se edita en Recetas y paquetes'
                                                  : 'Editar',
                                          icon: const Icon(Icons.edit,
                                              color: Color(0xFF004D40),
                                              size: 20),
                                          onPressed: producto.esReventaMateriaPrima || producto.esPaquete ? null : () {
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
                                        // PRODUCIR (elaborados y paquetes: descuenta sus componentes)
                                        if (producto.seProduce)
                                          IconButton(
                                          visualDensity: VisualDensity.compact,
                                            key: Key('producir_${producto.codigo}'),
                                            tooltip: 'Producir',
                                            icon: const Icon(Icons.soup_kitchen_outlined,
                                                color: Color(0xFF004D40), size: 20),
                                            onPressed: () => _producir(producto),
                                          ),
                                        // HISTORIAL DE STOCK
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          key: Key('historial_stock_${producto.codigo}'),
                                          tooltip: 'Ver historial de stock',
                                          icon: const Icon(Icons.history,
                                              color: Color(0xFF004D40), size: 20),
                                          onPressed: () => StockHistorialDialog.mostrar(context,
                                              codigo: producto.codigo, nombre: producto.nombre),
                                        ),
                                        // BOTÓN ARCHIVAR/DESARCHIVAR
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
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
      );
  }
}
