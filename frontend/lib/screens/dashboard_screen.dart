// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_scaffold.dart';
import '../services/api_service.dart';
import '../models/dashboard_models.dart';
import '../models/metodo_pago.dart';
import '../theme/app_colors.dart';
import '../widgets/cargando_diferido.dart';
import '../navigation/ir_a_seccion.dart';
import '../navigation/seccion.dart';
import '../utils/numeros.dart';
import '../utils/periodo.dart';
import '../widgets/resultado.dart';
import '../widgets/selector_periodo.dart';
import '../widgets/tabla_ajustada.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService? apiService;

  /// Para tests: el día que se toma como hoy en el selector de período.
  final DateTime? hoy;

  const DashboardScreen({super.key, this.apiService, this.hoy});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  // --- VARIABLES DE ESTADO ---
  late Periodo _periodo = Periodo.porDefecto(widget.hoy);
  int? _filtroMetodoPagoId;
  int? _filtroProductoId;

  /// Productos vendibles para el filtro: (id, nombre).
  List<(int, String)> _productos = const [];

  /// Métodos activos de Configuración (los del filtro).
  List<MetodoPago> _metodosPago = const [];
  
  DashboardResponse? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _cargarMetodosPago();
    _cargarProductos();
    _cargarDatos();
  }

  Future<void> _cargarMetodosPago() async {
    try {
      final metodos = await _apiService.getMetodosPago();
      if (mounted) setState(() => _metodosPago = metodos);
    } catch (_) {
      // Sin la lista, el filtro ofrece solo "Todos".
    }
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await _apiService.getProducts();
      final lista = <(int, String)>[
        for (final p in productos)
          if (p is Map && p['id'] != null && p['vendible'] != false)
            ((p['id'] as num).toInt(), p['nombre']?.toString() ?? ''),
      ]..sort((a, b) => a.$2.toLowerCase().compareTo(b.$2.toLowerCase()));
      if (mounted) setState(() => _productos = lista);
    } catch (_) {
      // Sin la lista, el filtro ofrece solo "Todos los productos".
    }
  }

  // --- LLAMADA A LA API ---
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getDashboardData(
        fechaDesde: _periodo.desde,
        fechaHasta: _periodo.hasta,
        metodoPagoId: _filtroMetodoPagoId,
        productoId: _filtroProductoId,
      );
      setState(() {
        _dashboardData = DashboardResponse.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // Al cambiar un filtro quedan los datos anteriores a la vista (con una
      // barra de carga) en vez de vaciar la pantalla.
      body: _isLoading && _dashboardData == null
          ? const CargandoDiferido(color: AppColors.verdeClaro)
          : _errorMessage != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 3,
                        child: _isLoading
                            ? const LinearProgressIndicator(color: AppColors.verdeClaro)
                            : null,
                      ),
                      _buildCabecera(),
                      const SizedBox(height: 32),
                      _buildTarjetasFinancieras(),
                      const SizedBox(height: 32),
                      _buildMetricasComerciales(),
                      const SizedBox(height: 32),
                      _buildAlertasOperativas(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.rojoEgresos),
          const SizedBox(height: 16),
          Text(
            'Hubo un problema: $_errorMessage',
            style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cargarDatos,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdeClaro),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- CABECERA Y FILTROS ---
  Widget _buildCabecera() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final filtros = Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SelectorPeriodo(
                  periodo: _periodo,
                  hoy: widget.hoy,
                  onCambio: (periodo) {
                    setState(() => _periodo = periodo);
                    _cargarDatos();
                  },
                ),
                _buildMetodoPagoDropdown(),
                _buildProductoDropdown(),
              ],
            );

            final titulo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SGI-U - Tablero de Control',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Resumen Ejecutivo',
                      style: TextStyle(fontSize: 18, color: Color(0xFF555555)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.info_outline, size: 18, color: Colors.grey.shade500),
                  ],
                ),
              ],
            );

            if (constraints.maxWidth < 700) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titulo,
                  const SizedBox(height: 16),
                  filtros,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: titulo),
                const SizedBox(width: 16),
                Expanded(flex: 7, child: filtros),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFF008A3D), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Visualiza la salud financiera y el desempeño de tu negocio en el período seleccionado.',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetodoPagoDropdown() {
    // Los métodos activos de Configuración; si el elegido se desactivó,
    // vuelve a "Todos".
    final seleccion = _metodosPago.any((m) => m.id == _filtroMetodoPagoId) ? _filtroMetodoPagoId : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int?>(
        key: const Key('dashboard_filtro_metodo_pago'),
        value: seleccion,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade700),
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Todos los métodos de pago')),
          for (final m in _metodosPago) DropdownMenuItem<int?>(value: m.id, child: Text(m.nombre)),
        ],
        onChanged: (value) {
          setState(() => _filtroMetodoPagoId = value);
          _cargarDatos();
        },
      ),
    );
  }

  Widget _buildProductoDropdown() {
    final seleccion = _productos.any((p) => p.$1 == _filtroProductoId) ? _filtroProductoId : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          DropdownButton<int?>(
            key: const Key('dashboard_filtro_producto'),
            value: seleccion,
            underline: const SizedBox.shrink(),
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade700),
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos los productos')),
              for (final p in _productos) DropdownMenuItem<int?>(value: p.$1, child: Text(p.$2)),
            ],
            onChanged: (value) {
              setState(() => _filtroProductoId = value);
              _cargarDatos();
            },
          ),
        ],
      ),
    );
  }

  // --- BLOQUE 1: SALUD FINANCIERA ---
  Widget _buildTarjetasFinancieras() {
    final kpis = _dashboardData!.kpis;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Me está quedando plata?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF008A3D)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStandardCard(
                titulo: 'Ingresos del Período',
                monto: formatter.format(kpis.ingresosPeriodo),
                subtitulo: 'Total dinero entrante',
                montoColor: const Color(0xFF008A3D),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStandardCard(
                titulo: 'Egresos del Período',
                monto: kpis.egresosPeriodo == null ? '—' : formatter.format(kpis.egresosPeriodo),
                subtitulo: 'Total dinero saliente',
                montoColor: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildSaldoCard(
                titulo: 'Saldo Neto de Caja',
                monto: kpis.saldoNeto == null ? '—' : formatter.format(kpis.saldoNeto),
                subtitulo: 'Capital disponible',
                margen: kpis.margenNetoPorcentaje == null
                    ? '—'
                    : '${kpis.margenNetoPorcentaje! >= 0 ? '+' : ''}${kpis.margenNetoPorcentaje!.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTarjetasGanancia(),
      ],
    );
  }

  /// Costo de lo vendido, ganancia bruta y ganancia neta, con el mismo
  /// estilo que las tarjetas de arriba: pesos grandes y el % chico al lado.
  Widget _buildTarjetasGanancia() {
    final r = _dashboardData!.kpis.resultado;
    final neta = r.gananciaNeta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStandardCard(
            key: const Key('dashboard_costo'),
            titulo: 'Costo',
            monto: formatPesos(r.costoVendido),
            subtitulo: 'Costo de lo vendido',
            montoColor: const Color(0xFF555555),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStandardCard(
            key: const Key('dashboard_ganancia'),
            titulo: 'Ganancia',
            monto: formatPesosConSigno(r.gananciaBruta),
            porcentaje: r.margenBrutoPorcentaje,
            subtitulo: 'Ventas − costo',
            montoColor: colorResultado(r.gananciaBruta),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStandardCard(
            key: const Key('dashboard_ganancia_neta'),
            titulo: 'Ganancia neta',
            ayuda: 'Lo que te queda después de pagar los gastos: alquiler, luz, '
                'sueldos y otros. Las compras de mercadería no se restan acá: '
                'su costo ya está en "Costo" cuando vendés lo que hiciste con ella.',
            monto: neta == null ? '—' : formatPesosConSigno(neta),
            porcentaje: r.margenNetoPorcentaje,
            subtitulo: neta == null
                ? 'Los gastos no se calculan por producto'
                : 'Después de ${formatPesos(r.gastos ?? 0)} de gastos',
            montoColor: neta == null ? const Color(0xFF555555) : colorResultado(neta),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardCard({
    Key? key,
    required String titulo,
    required String monto,
    required String subtitulo,
    required Color montoColor,
    double? porcentaje,
    String? ayuda,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
              ),
              if (ayuda != null) ...[
                const SizedBox(width: 6),
                AyudaInfo(ayuda),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(monto, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: montoColor)),
                if (porcentaje != null) ...[
                  const SizedBox(width: 8),
                  Text(formatPorcentaje(porcentaje),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: montoColor)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitulo, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _buildSaldoCard({required String titulo, required String monto, required String subtitulo, required String margen}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF227B63),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF227B63).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white70)),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(monto, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(subtitulo,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              Text('Margen Neto: $margen', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  // --- BLOQUE 2: MOTOR COMERCIAL ---
  Widget _buildMetricasComerciales() {
    final kpis = _dashboardData!.kpis;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo se está moviendo mi negocio?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF008A3D)),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      titulo: 'Cantidad de Ventas',
                      valor: kpis.cantidadVentas.toString(),
                      subtitulo: 'Transacciones',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildMetricCard(
                      titulo: 'Ticket Promedio',
                      valor: formatter.format(kpis.ticketPromedio),
                      subtitulo: 'por compra',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: _buildChartPlaceholder(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String titulo, required String valor, required String subtitulo}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const SizedBox(height: 16),
          Text(valor, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF111111))),
          const SizedBox(height: 8),
          Text(subtitulo, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 185,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Evolución del Dinero', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  children: [Text('Diario', style: TextStyle(fontSize: 12)), SizedBox(width: 4), Icon(Icons.keyboard_arrow_down, size: 14)],
                ),
              )
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('Gráfico de barras próximamente...', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- BLOQUE 3: ALERTAS OPERATIVAS ---
  Widget _buildAlertasOperativas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas Operativas (El Día a Día)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF008A3D)),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStockCriticoCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildTopProductosCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildStockCriticoCard() {
    final listaStock = _dashboardData!.graficos.productosConMenorStock;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Stock Crítico - Reposición Urgente', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          DataTable(
            headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            columnSpacing: 16,
            horizontalMargin: 0,
            dividerThickness: 1,
            columns: const [
              DataColumn(columnWidth: columnaFlexible, label: Text('Producto')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Stock Actual')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Stock Mínimo')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Estado')),
            ],
            rows: listaStock.isEmpty
                ? [
                    const DataRow(cells: [
                      DataCell(Text('Todo en orden')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ])
                  ]
                : listaStock.map((p) {
                    bool isAgotado = p.estado == 'AGOTADO' || p.stockActual == 0;
                    return _buildStockRow(p.nombre, '${p.stockActual} un.', '${p.stockMinimo} un.', p.estado, isAgotado);
                  }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              key: const Key('dashboard_ver_inventario'),
              onPressed: () => IrASeccion.de(context)?.call(Seccion.catalogo),
              icon: const Text('Ver inventario completo', style: TextStyle(color: Color(0xFF008A3D))),
              label: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF008A3D)),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildStockRow(String nombre, String actual, String minimo, String estado, bool agotado) {
    return DataRow(
      cells: [
        DataCell(Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(actual, style: TextStyle(color: agotado ? const Color(0xFFD32F2F) : const Color(0xFFE65100), fontWeight: FontWeight.bold))),
        DataCell(Text(minimo)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: agotado ? const Color(0xFFD32F2F) : const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(4)),
          child: Text(estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: agotado ? Colors.white : const Color(0xFFE65100))),
        )),
      ],
    );
  }

  Widget _buildTopProductosCard() {
    final listaTop = _dashboardData!.graficos.topProductosMasVendidos;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    int ranking = 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Top Productos Más Vendidos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          DataTable(
            key: const Key('dashboard_top_productos'),
            headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            columnSpacing: 16,
            horizontalMargin: 0,
            dividerThickness: 1,
            columns: const [
              DataColumn(columnWidth: columnaAjustable, label: Text('#')),
              DataColumn(columnWidth: columnaFlexible, label: Text('Producto')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Cant. Vendida')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Monto Generado')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia')),
            ],
            rows: listaTop.isEmpty
                ? [
                    const DataRow(cells: [
                      DataCell(Text('-')),
                      DataCell(Text('Sin ventas en el período')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ])
                  ]
                : listaTop.map((p) {
                    final fila = _buildTopRow(ranking.toString(), p.nombre, p.cantidadVendida.toString(), formatter.format(p.montoTotal), ranking == 1 ? 1.0 : (ranking == 2 ? 0.8 : 0.5), p.ganancia);
                    ranking++;
                    return fila;
                  }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              key: const Key('dashboard_ver_reporte'),
              onPressed: () => IrASeccion.de(context)?.call(Seccion.balance),
              icon: const Text('Ver reporte completo', style: TextStyle(color: Color(0xFF008A3D))),
              label: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF008A3D)),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildTopRow(String ranking, String nombre, String cantidad, String monto, double barWidth, double? ganancia) {
    return DataRow(
      cells: [
        DataCell(Text(ranking, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis)),
        DataCell(Text(cantidad, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Row(
          children: [
            SizedBox(width: 85, child: Text(monto)),
            const SizedBox(width: 8),
            Container(
              height: 6,
              width: 40 * barWidth,
              decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(4)),
            ),
          ],
        )),
        DataCell(Text(
          ganancia == null ? '-' : formatPesosConSigno(ganancia),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ganancia == null ? const Color(0xFF333333) : colorResultado(ganancia),
          ),
        )),
      ],
    );
  }
}