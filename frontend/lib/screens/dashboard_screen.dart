// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/side_menu.dart';
import '../services/api_service.dart';
import '../models/dashboard_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  // --- VARIABLES DE ESTADO ---
  DateTime _fechaDesde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaHasta = DateTime.now();
  
  DashboardResponse? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- LLAMADA A LA API ---
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getDashboardData(
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
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

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rangoSeleccionado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaDesde, end: _fechaHasta),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
              maxHeight: 580,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF008A3D),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF222222),
                ),
              ),
              child: child!,
            ),
          ),
        );
      },
    );

    if (rangoSeleccionado != null) {
      setState(() {
        _fechaDesde = rangoSeleccionado.start;
        _fechaHasta = rangoSeleccionado.end;
      });
      _cargarDatos(); // Re-carga los datos automáticamente al cambiar la fecha
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SideMenu(rutaActual: '/dashboard'),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008A3D)),
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFD32F2F)),
          const SizedBox(height: 16),
          Text(
            'Hubo un problema: $_errorMessage',
            style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cargarDatos,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008A3D)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
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
            ),
            Row(
              children: [
                _buildFiltroDropdown(
                  Icons.calendar_today_outlined, 
                  '${DateFormat('dd/MM/yyyy').format(_fechaDesde)} - ${DateFormat('dd/MM/yyyy').format(_fechaHasta)}',
                  onTap: _seleccionarRangoFechas,
                ),
                const SizedBox(width: 12),
                _buildFiltroDropdown(Icons.credit_card_outlined, 'Todos los métodos de pago'),
                const SizedBox(width: 12),
                _buildFiltroDropdown(Icons.inventory_2_outlined, 'Todos los productos'),
              ],
            ),
          ],
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
            const Text(
              'Visualiza la salud financiera y el desempeño de tu negocio en el período seleccionado.',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltroDropdown(IconData icon, String texto, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Text(texto, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade700),
          ],
        ),
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
                monto: formatter.format(kpis.egresosPeriodo),
                subtitulo: 'Total dinero saliente',
                montoColor: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildSaldoCard(
                titulo: 'Saldo Neto de Caja',
                monto: formatter.format(kpis.saldoNeto),
                subtitulo: 'Capital disponible',
                margen: '${kpis.margenNetoPorcentaje >= 0 ? '+' : ''}${kpis.margenNetoPorcentaje.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandardCard({required String titulo, required String monto, required String subtitulo, required Color montoColor}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const SizedBox(height: 12),
          Text(monto, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: montoColor)),
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
        boxShadow: [BoxShadow(color: const Color(0xFF227B63).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white70)),
          const SizedBox(height: 12),
          Text(monto, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtitulo, style: const TextStyle(fontSize: 13, color: Colors.white70)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
              DataColumn(label: Text('Producto')),
              DataColumn(label: Text('Stock Actual')),
              DataColumn(label: Text('Stock Mínimo')),
              DataColumn(label: Text('Estado')),
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
              onPressed: () {},
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
        DataCell(Text(nombre, style: const TextStyle(fontWeight: FontWeight.w500))),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Top Productos Más Vendidos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          DataTable(
            headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            columnSpacing: 16,
            horizontalMargin: 0,
            dividerThickness: 1,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Producto')),
              DataColumn(label: Text('Cant. Vendida')),
              DataColumn(label: Text('Monto Generado')),
            ],
            rows: listaTop.isEmpty
                ? [
                    const DataRow(cells: [
                      DataCell(Text('-')),
                      DataCell(Text('Sin ventas en el período')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ])
                  ]
                : listaTop.map((p) {
                    final fila = _buildTopRow(ranking.toString(), p.nombre, p.cantidadVendida.toString(), formatter.format(p.montoTotal), ranking == 1 ? 1.0 : (ranking == 2 ? 0.8 : 0.5));
                    ranking++;
                    return fila;
                  }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Text('Ver reporte completo', style: TextStyle(color: Color(0xFF008A3D))),
              label: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF008A3D)),
            ),
          )
        ],
      ),
    );
  }

  DataRow _buildTopRow(String ranking, String nombre, String cantidad, String monto, double barWidth) {
    return DataRow(
      cells: [
        DataCell(Text(ranking, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(nombre)),
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
      ],
    );
  }
}