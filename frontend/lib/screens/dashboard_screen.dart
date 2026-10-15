// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../services/api_service.dart';
import '../models/dashboard_models.dart';
import '../models/metodo_pago.dart';
import '../theme/app_colors.dart';
import '../widgets/cargando_diferido.dart';
import '../navigation/ir_a_seccion.dart';
import '../navigation/seccion.dart';
import '../utils/numeros.dart';
import '../widgets/resultado.dart';
import '../widgets/selector_periodo.dart';
import '../utils/periodo.dart';
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
        fechaDesde: _periodo.desde,
        fechaHasta: _periodo.hasta,
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // Al cambiar el período quedan los datos anteriores a la vista (con una
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
        const Text(
          'Inicio',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cómo le va a tu negocio',
          style: TextStyle(fontSize: 18, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.start,
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

  // --- BLOQUE 1: ¿CUÁNTO GANÉ? ---
  Widget _buildTarjetasFinancieras() {
    final kpis = _dashboardData!.kpis;
    final r = kpis.resultado;
    final ventas = kpis.cantidadVentas == 1 ? '1 venta' : '${kpis.cantidadVentas} ventas';

    final tarjetas = [
      _buildKpiCard(
        key: const Key('inicio_vendiste'),
        titulo: 'Vendiste',
        monto: formatPesos(r.ventas),
        subtitulo: kpis.cantidadVentas == 0
            ? 'Sin ventas en el período'
            : '$ventas · promedio ${formatPesos(kpis.ticketPromedio)}',
      ),
      _buildKpiCard(
        key: const Key('inicio_te_costo'),
        titulo: 'Te costó',
        monto: formatPesos(r.costoVendido),
        subtitulo: 'Lo que te costó hacer o comprar lo que vendiste',
      ),
      _buildKpiCard(
        key: const Key('inicio_ganancia_bruta'),
        titulo: 'Ganancia bruta',
        monto: formatPesosConSigno(r.gananciaBruta),
        montoColor: colorResultado(r.gananciaBruta),
        porcentaje: r.margenBrutoPorcentaje,
        subtitulo: 'Lo que te dejan los productos (vendiste − te costó)',
      ),
      _buildKpiCard(
        key: const Key('inicio_ganancia_neta'),
        titulo: 'Ganancia neta',
        ayuda: 'Lo que te queda después de pagar los gastos: alquiler, luz, '
            'sueldos y otros. Las compras de mercadería no se restan acá: su '
            'costo ya está en "Te costó" cuando vendés lo que hiciste con ella.',
        monto: formatPesosConSigno(r.gananciaNeta),
        montoColor: colorResultado(r.gananciaNeta),
        porcentaje: r.margenNetoPorcentaje,
        subtitulo: r.otrosIngresos > 0
            ? 'Después de ${formatPesos(r.gastos)} de gastos y con ${formatPesos(r.otrosIngresos)} de otros ingresos'
            : 'Después de ${formatPesos(r.gastos)} de gastos',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Me está quedando plata?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF008A3D)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          // Cuatro en fila; en pantallas angostas, de a dos.
          final porFila = constraints.maxWidth >= 900 ? 4 : 2;
          const separacion = 20.0;
          final ancho = (constraints.maxWidth - separacion * (porFila - 1)) / porFila;
          return Wrap(
            spacing: separacion,
            runSpacing: separacion,
            children: [for (final t in tarjetas) SizedBox(width: ancho, child: t)],
          );
        }),
      ],
    );
  }

  /// Pesos primero y grandes; el % chico al lado.
  Widget _buildKpiCard({
    required Key key,
    required String titulo,
    required String monto,
    required String subtitulo,
    Color montoColor = const Color(0xFF111111),
    double? porcentaje,
    String? ayuda,
  }) {
    return Container(
      key: key,
      height: 150,
      padding: const EdgeInsets.all(20),
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
                child: Text(titulo,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
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
                Text(monto, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: montoColor)),
                if (porcentaje != null) ...[
                  const SizedBox(width: 8),
                  Text(formatPorcentaje(porcentaje),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: montoColor)),
                ],
              ],
            ),
          ),
          const Spacer(),
          Text(subtitulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
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
