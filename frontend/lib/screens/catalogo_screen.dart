import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../blocs/pos_bloc.dart';
import '../blocs/pos_event.dart';
import '../blocs/pos_state.dart';
import '../widgets/producto_form_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/campo_buscador.dart';
import '../widgets/app_data_table.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/estado_chip.dart';
import '../widgets/section_header.dart';
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.espacioChico,
          vertical: AppSpacing.espacioMinimo),
      decoration: const BoxDecoration(
        color: AppColors.fondoApp,
        borderRadius: AppRadii.bordeChico,
      ),
      child: Text(etiqueta,
          style: AppTypography.etiqueta.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBadge(bool isActive) {
    return EstadoChip(
      etiqueta: isActive ? 'Activo' : 'Inactivo',
      tono: isActive ? TonoEstado.exito : TonoEstado.neutro,
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
              color: AppColors.fondoSuperficie,
              child: TabBar(
                key: Key('tabs_productos'),
                labelColor: AppColors.marcaActiva,
                indicatorColor: AppColors.marcaActiva,
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
          style: AppTypography.textoChico.copyWith(
              color: negativo ? AppColors.error : AppColors.textoSecundario,
              fontWeight: negativo ? FontWeight.bold : FontWeight.normal),
        ),
        if (producto.seProduce && producto.puedeProducir != null)
          Text('Puedo producir hasta ${producto.puedeProducir}',
              key: Key('puede_producir_${producto.codigo}'),
              style: AppTypography.pie
                  .copyWith(color: AppColors.textoInactivo)),
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
    final mensaje = 'Se produjeron ${formatDecimal(resultado.cantidad)} ${resultado.nombre}'
        '${resultado.conFaltantes ? ' (con faltantes: hay stock negativo)' : ''}. Consumo: $consumos.';
    if (resultado.conFaltantes) {
      AppSnackBar.info(context, mensaje);
    } else {
      AppSnackBar.exito(context, mensaje);
    }
  }

  Widget _productos(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppSnackBar.error(context, state.errorMessage!);
            context.read<PosBloc>().add(const ClearError());
          }
          if (state.successMessage != null) {
            AppSnackBar.exito(context, state.successMessage!);
            context.read<PosBloc>().add(const ClearSuccess());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.espacioPantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              SectionHeader(
                titulo: 'Productos',
                accion: AppButton.primary(
                  icono: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ProductoFormDialog(),
                    );
                  },
                  child: const Text('Agregar Nuevo Producto'),
                ),
              ),
              const SizedBox(height: AppSpacing.espacioSeccion),

              // --- BUSCADOR Y CHIPS DE CATEGORÍA ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   CampoBuscador(
                     controller: _searchController,
                     hintText: 'Buscar producto...',
                     ancho: 320,
                     conSombra: false,
                     iconoAlFrente: false,
                   ),
                  const SizedBox(width: AppSpacing.espacioEstandar),
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
                                padding: const EdgeInsets.only(
                                    right: AppSpacing.espacioChico),
                                child: FilterChip(
                                  key: ValueKey('catalogo_category_chip_$cat'),
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: AppColors.marcaActiva
                                      .withValues(alpha: 0.2),
                                  checkmarkColor: AppColors.marcaActiva,
                                  labelStyle: AppTypography.etiqueta.copyWith(
                                    color: isSelected
                                        ? AppColors.marcaActiva
                                        : AppColors.textoPrincipal,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
              const SizedBox(height: AppSpacing.espacioEstandar),

              // --- CAJA BLANCA (TABLA + PAGINACIÓN) ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.fondoSuperficie,
                    borderRadius: AppRadii.bordeTarjeta,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.textoPrincipal.withValues(alpha: 0.03),
                          blurRadius: 10)
                    ],
                  ),
                  child: BlocBuilder<PosBloc, PosState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const CargandoDiferido(
                            color: AppColors.marcaActiva);
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
                            child: AppDataTable(
                              key: const Key('tabla_productos'),
                              altoFilaMaximo: double.infinity,
                              separacionColumnas: AppSpacing.espacioEstandar,
                              margenHorizontal: AppSpacing.espacioEstandar,
                              columnas: const [
                                DataColumn(columnWidth: columnaAjustable, label: Text('Código ↓')),
                                DataColumn(
                                    columnWidth: columnaFlexible,
                                    label: Text('Nombre del Producto')),
                                DataColumn(columnWidth: columnaAjustable, label: Text('Tipo')),
                                DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Categoría')),
                                DataColumn(
                                    columnWidth: columnaAjustable,
                                    numeric: true,
                                    label: Text('Precio Unit.')),
                                DataColumn(
                                    columnWidth: columnaAjustable,
                                    numeric: true,
                                    label: Text('Ganancia')),
                                DataColumn(columnWidth: columnaFlexibleSecundaria, label: Text('Stock')),
                                DataColumn(columnWidth: columnaAjustable, label: Text('Estado')),
                                DataColumn(columnWidth: columnaAjustable, label: Text('Acciones')),
                              ],
                              filas: paginatedProducts.map((producto) {
                                return DataRow(cells: [
                                  DataCell(Text(producto.codigo,
                                      style: AppTypography.textoChico.copyWith(
                                          color: AppColors.textoSecundario))),
                                  DataCell(Text(producto.nombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.textoChico.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textoPrincipal))),
                                  DataCell(_buildTipo(producto)),
                                  DataCell(Text(producto.categoria ?? '-',
                                      maxLines: 2,
                                      style: AppTypography.textoChico.copyWith(
                                          color: AppColors.textoSecundario))),
                                  DataCell(Text(
                                      '${formatPesos(producto.precioUnitario)}'
                                      '${producto.precioManual ? '\n(a mano)' : ''}',
                                      key: Key('precio_${producto.codigo}'),
                                      style: AppTypography.textoChico.copyWith(
                                          color: AppColors.textoSecundario))),
                                  // Ganancia por unidad en $ y en %.
                                  DataCell(Text(
                                      producto.gananciaPesos == null
                                          ? '—'
                                          : '${formatPesos(producto.gananciaPesos!)}'
                                              '${producto.porcentajeReal != null ? '\n${formatDecimal(producto.porcentajeReal!, decimales: 1)} %' : ''}',
                                      key: Key('ganancia_${producto.codigo}'),
                                      style: AppTypography.textoChico.copyWith(
                                          color: AppColors.exito,
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
                                            color: AppColors.marcaActiva,
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
                                              color: AppColors.marcaActiva, size: 20),
                                          onPressed: () => _producir(producto),
                                        ),
                                      // HISTORIAL DE STOCK
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        key: Key('historial_stock_${producto.codigo}'),
                                        tooltip: 'Ver historial de stock',
                                        icon: const Icon(Icons.history,
                                            color: AppColors.marcaActiva, size: 20),
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
                                            color: AppColors.marcaActiva,
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
                          // FOOTER (PAGINACIÓN)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.espacioEstandar,
                                horizontal: AppSpacing.espacioSeccion),
                            decoration: const BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: AppColors.bordeSuave))),
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
                                      horizontal: AppSpacing.espacioEstandar,
                                      vertical: AppSpacing.espacioChico),
                                  decoration: const BoxDecoration(
                                    color: AppColors.marcaActiva,
                                    borderRadius: AppRadii.bordeChico,
                                  ),
                                  child: Text('$_currentPage',
                                      style: AppTypography.etiqueta.copyWith(
                                          color: AppColors.sobreMarca,
                                          fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < totalPages
                                      ? () =>
                                          setState(() => _currentPage++)
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.espacioSeccion),
                                Text(
                                    'Página $_currentPage de $totalPages',
                                    style: AppTypography.textoChico.copyWith(
                                        color: AppColors.textoInactivo)),
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
