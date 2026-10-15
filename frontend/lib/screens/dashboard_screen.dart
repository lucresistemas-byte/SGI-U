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
import '../widgets/tabla_ajustada.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService? apiService;

  const DashboardScreen({super.key, this.apiService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  // --- VARIABLES DE ESTADO ---
  DateTime _fechaDesde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaHasta = DateTime.now();
  int? _filtroMetodoPagoId;

  /// Métodos activos de Configuración (los del filtro).
  List<MetodoPago> _metodosPago = const [];
  
  DashboardResponse? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _cargarMetodosPago();
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
        metodoPagoId: _filtroMetodoPagoId,
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
    return AppScaffold(
      body: _isLoading
          ? const CargandoDiferido(color: AppColors.verdeClaro)
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
                _buildFiltroDropdown(
                  Icons.calendar_today_outlined,
                  '${DateFormat('dd/MM/yyyy').format(_fechaDesde)} - ${DateFormat('dd/MM/yyyy').format(_fechaHasta)}',
                  onTap: _seleccionarRangoFechas,
                ),
                _buildMetodoPagoDropdown(),
              ],
            );

            const titulo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inicio',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
                ),
                SizedBox(height: 6),
                Text(
                  'Cómo le va a tu negocio',
                  style: TextStyle(fontSize: 18, color: Color(0xFF555555)),
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
                const Expanded(flex: 5, child: titulo),
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
                'Lo que vendiste, lo que te costó y lo que ganaste en el período elegido.',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Flexible(
              child: Text(texto,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
            ),
            const SizedBox(width: 10),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade700),
          ],
        ),
      ),
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
                titulo: 'Ingresos del período',
                monto: formatter.format(kpis.ingresosPeriodo),
                subtitulo: 'Todo lo que entró',
                montoColor: const Color(0xFF008A3D),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStandardCard(
                titulo: 'Egresos del período',
                monto: formatter.format(kpis.egresosPeriodo),
                subtitulo: 'Todo lo que salió',
                montoColor: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildSaldoCard(
                titulo: 'Caja del período',
                monto: formatter.format(kpis.saldoNeto),
                subtitulo: 'Entró menos salió',
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
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

  Widget _buildSaldoCard({required String titulo, required String monto, required String subtitulo}) {
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
          Text(monto, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitulo, style: const TextStyle(fontSize: 13, color: Colors.white70)),
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
              child: _buildMetricCard(
                titulo: 'Ventas',
                valor: kpis.cantidadVentas.toString(),
                subtitulo: 'en el período',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildMetricCard(
                titulo: 'Promedio por venta',
                valor: formatter.format(kpis.ticketPromedio),
                subtitulo: 'lo que gasta cada cliente',
              ),
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

  // --- BLOQUE 3: ALERTAS OPERATIVAS ---
  Widget _buildAlertasOperativas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Para tener en cuenta',
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
          const Text('Productos con poco stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          DataTable(
            headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            columnSpacing: 16,
            horizontalMargin: 0,
            dividerThickness: 1,
            columns: const [
              DataColumn(columnWidth: columnaFlexible, label: Text('Producto')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Hay')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Mínimo')),
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
              key: const Key('inicio_ver_productos'),
              onPressed: () => IrASeccion.de(context)?.call(Seccion.catalogo),
              icon: const Text('Ver en Productos', style: TextStyle(color: Color(0xFF008A3D))),
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
    final top = _dashboardData!.graficos.topProductosPorGanancia;

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
          const Text('Lo que más plata te deja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const SizedBox(height: 4),
          const Text('Los 5 productos que más ganancia dejaron (lo vendido menos lo que costó)',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Sin ventas en el período', style: TextStyle(color: Color(0xFF666666))),
            )
          else
            SizedBox(
              width: double.infinity,
              child: DataTable(
                key: const Key('inicio_top_ganancia'),
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                columnSpacing: 16,
                horizontalMargin: 0,
                dividerThickness: 1,
                columns: const [
                  DataColumn(columnWidth: columnaAjustable, label: Text('#')),
                  DataColumn(columnWidth: columnaFlexible, label: Text('Producto')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Vendidos'), numeric: true),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Ventas'), numeric: true),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia'), numeric: true),
                ],
                rows: [
                  for (final (i, p) in top.indexed)
                    DataRow(cells: [
                      DataCell(Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(p.nombre, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      DataCell(Text('${p.cantidadVendida}')),
                      DataCell(Text(formatPesos(p.ventas))),
                      DataCell(Text(
                        formatPesosConSigno(p.ganancia),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.ganancia < 0 ? const Color(0xFFD32F2F) : const Color(0xFF008A3D),
                        ),
                      )),
                    ]),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              key: const Key('inicio_ver_ganancias'),
              onPressed: () => IrASeccion.de(context)?.call(Seccion.balance),
              icon: const Text('Ver detalle en Ganancias', style: TextStyle(color: Color(0xFF008A3D))),
              label: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF008A3D)),
            ),
          )
        ],
      ),
    );
  }
}
