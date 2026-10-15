import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../widgets/app_scaffold.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';
import '../utils/parsers.dart';
import '../models/categoria_movimiento.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/tabla_ajustada.dart';
import '../widgets/resultado.dart';
import '../widgets/selector_periodo.dart';
import '../utils/periodo.dart';
import '../utils/numeros.dart';

class BalanceScreen extends StatefulWidget {
  /// Para tests: el día que se toma como hoy en el selector de período.
  final DateTime? hoy;

  const BalanceScreen({super.key, this.hoy});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  late Periodo _periodo = Periodo.porDefecto(widget.hoy);

  @override
  void initState() {
    super.initState();
    _cargarBalance();
  }

  void _cargarBalance() {
    context.read<FinanzasBloc>().add(CargarBalance(_periodo.desde, _periodo.hasta));
  }

  Future<void> _exportarReportePdf() async {
    final state = context.read<FinanzasBloc>().state;

    if (state is! BalanceLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargue datos de balance antes de exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generando PDF...'),
          ],
        ),
      ),
    );

    try {
      await PdfService.generarYDescargarBalance(
        fechaInicio: _periodo.desde,
        fechaFin: _periodo.hasta,
        totalIngresos: parseDouble(state.balance['totalIngresos']),
        totalEgresos: parseDouble(state.balance['totalEgresos']),
        margenNeto: parseDouble(state.balance['margenNeto']),
        movimientos: state.balance['movimientos'] ?? [],
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ganancias',
                  style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111111)),
                ),
                ElevatedButton.icon(
                  onPressed: _exportarReportePdf,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text('Exportar reporte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    minimumSize: const Size(250, 56),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFiltrosCard(),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<FinanzasBloc, FinanzasState>(
                builder: (context, state) {
                  if (state is BalanceLoading) {
                    return const CargandoDiferido();
                  }
                  if (state is BalanceLoaded) {
                    return _buildMetricasYTabla(state.balance);
                  }
                  if (state is MovimientosError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _cargarBalance,
                              child: const Text('Reintentar')),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: SelectorPeriodo(
        periodo: _periodo,
        hoy: widget.hoy,
        onCambio: (periodo) {
          setState(() => _periodo = periodo);
          _cargarBalance();
        },
      ),
    );
  }

  Widget _buildMetricasYTabla(Map<String, dynamic> balance) {
    final ingresos = parseDouble(balance['totalIngresos']);
    final egresos = parseDouble(balance['totalEgresos']);
    final margenNeto = parseDouble(balance['margenNeto']);
    final costoTotal = parseDouble(balance['costoTotal']);
    final gananciaReal = parseDouble(balance['gananciaReal']);
    final colorMargen =
        margenNeto >= 0 ? const Color(0xFF006B3D) : const Color(0xFFFF0000);

    return Column(
      children: [
        Row(
          children: [
            _buildMetricaCard(
              titulo: 'Ingresos (entró)',
              valor: ingresos,
              colorValor: const Color(0xFF006B3D),
              icon: Icons.trending_up,
              iconBgColor: const Color(0xFFEAF8EF),
              iconColor: const Color(0xFF006B3D),
            ),
            const SizedBox(width: 24),
            _buildMetricaCard(
              titulo: 'Egresos (salió)',
              valor: egresos,
              colorValor: const Color(0xFFFF0000),
              icon: Icons.trending_down,
              iconBgColor: const Color(0xFFFFEAEA),
              iconColor: const Color(0xFFFF0000),
            ),
            const SizedBox(width: 24),
            _buildMetricaCard(
              titulo: 'Caja del período',
              valor: margenNeto,
              colorValor: colorMargen,
              icon: Icons.wallet_outlined,
              iconBgColor: const Color(0xFFEAF1FF),
              iconColor: const Color(0xFF006B3D),
            ),
            const SizedBox(width: 24),
            _buildCostoBeneficioCard(
              costoTotal: costoTotal,
              gananciaReal: gananciaReal,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildTablaMovimientos(balance['movimientos'] ?? [])),
      ],
    );
  }

  Widget _buildCostoBeneficioCard({
    required double costoTotal,
    required double gananciaReal,
  }) {
    final formatter =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    final colorGanancia =
        gananciaReal >= 0 ? const Color(0xFF006B3D) : const Color(0xFFFF0000);

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth;
          final double circleSize = (cardWidth * 0.22).clamp(36.0, 56.0);
          final double iconSize = circleSize * 0.5;
          final double titleSize = (cardWidth * 0.08).clamp(14.0, 16.0);
          final double moneySize = (cardWidth * 0.12).clamp(15.0, 22.0);

          return Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Costo y ganancia',
                      style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666666)),
                    ),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAF8EF), shape: BoxShape.circle),
                      child: Icon(Icons.show_chart,
                          size: iconSize, color: const Color(0xFF006B3D)),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Te costó',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF888888))),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatter.format(costoTotal),
                              style: TextStyle(
                                  fontSize: moneySize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF555555)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text('Ganancia neta',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11, color: Color(0xFF888888))),
                              ),
                              SizedBox(width: 4),
                              AyudaInfo(
                                  'Lo que te queda después de pagar los gastos (alquiler, luz, sueldos, otros). Las compras de mercadería no se restan: su costo ya está en "Te costó".'),
                            ],
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              formatPesosConSigno(gananciaReal),
                              style: TextStyle(
                                  fontSize: moneySize,
                                  fontWeight: FontWeight.bold,
                                  color: colorGanancia),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricaCard({
    required String titulo,
    required double valor,
    required Color colorValor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final formatter =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth;
          final double circleSize = (cardWidth * 0.22).clamp(36.0, 56.0);
          final double iconSize = circleSize * 0.5;
          final double titleSize = (cardWidth * 0.08).clamp(14.0, 16.0);
          final double moneySize = (cardWidth * 0.15).clamp(20.0, 28.0);

          return Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: titleSize, color: const Color(0xFF666666))),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatter.format(valor),
                          style: TextStyle(
                              fontSize: moneySize,
                              fontWeight: FontWeight.bold,
                              color: colorValor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                          color: iconBgColor, shape: BoxShape.circle),
                      child: Icon(icon, size: iconSize, color: iconColor),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTablaMovimientos(List<dynamic> movimientos) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Detalle de Movimientos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: TablaAjustada(
              tabla: DataTable(
                columnSpacing: 24,
                horizontalMargin: 24,
                headingRowHeight: 50,
                headingRowColor: WidgetStateProperty.resolveWith(
                    (_) => const Color(0xFFF6F6F6)),
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                dividerThickness: 1,
                columns: const [
                  DataColumn(columnWidth: columnaAjustable, label: Text('Fecha/Hora')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Tipo')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Monto')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Costo')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Método de Pago')),
                  DataColumn(columnWidth: columnaAjustable, label: Text('Categoría')),
                  DataColumn(columnWidth: columnaFlexible, label: Text('Descripción')),
                ],
                rows: movimientos.map((mov) {
                  String tipoRaw = parseString(mov['tipo']);
                  String tipoDisplay =
                      tipoRaw.toLowerCase() == 'ingreso'
                          ? 'Ingreso'
                          : 'Egreso';
                  bool isIngreso = tipoDisplay == 'Ingreso';

                  String metodoRaw = parseString(mov['metodoPago']);
                  String metodoDisplay = _parseMetodoPago(metodoRaw);

                  double monto = parseDouble(mov['monto']);
                  // Null en los egresos: un gasto no tiene costo ni ganancia.
                  final double? costo =
                      mov['costo'] == null ? null : parseDouble(mov['costo']);
                  final double? ganancia = mov['ganancia'] == null
                      ? null
                      : parseDouble(mov['ganancia']);
                  String fechaHora =
                      _formatFechaHora(parseString(mov['fechaHora']));
                  String categoria = CategoriaMovimiento.etiquetaDe(
                      mov['categoria']?.toString());
                  String descripcion =
                      parseString(mov['descripcion'], '-');

                  return DataRow(cells: [
                    DataCell(Text(fechaHora,
                        style: const TextStyle(color: Colors.black87))),
                    DataCell(_buildTipoBadge(tipoDisplay, isIngreso)),
                    DataCell(
                      Text(
                        (isIngreso ? '+ ' : '- ') + _formatMonto(monto),
                        style: TextStyle(
                          color: isIngreso
                              ? const Color(0xFF008A3D)
                              : const Color(0xFFFF2E2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        costo == null ? '—' : _formatMonto(costo),
                        style: const TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                    DataCell(
                      Text(
                        ganancia == null
                            ? '—'
                            : (ganancia >= 0 ? '+ ' : '') + _formatMonto(ganancia),
                        style: TextStyle(
                          color: ganancia == null
                              ? const Color(0xFF666666)
                              : ganancia >= 0
                                  ? const Color(0xFF008A3D)
                                  : const Color(0xFFFF2E2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(_buildMetodoBadge(metodoDisplay)),
                    DataCell(Text(categoria)),
                    DataCell(Text(descripcion,
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _parseMetodoPago(String raw) {
    String normal = raw.toLowerCase().replaceAll('_', ' ');
    if (normal.contains('efectivo') || normal == '1') return 'Efectivo';
    if (normal.contains('mercado') || normal == '2') return 'Mercado Pago';
    if (normal.contains('tarjeta') || normal == '3') return 'Tarjeta';
    if (normal.contains('transferencia') || normal == '4') {
      return 'Transferencia';
    }
    return raw;
  }

  String _formatFechaHora(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildTipoBadge(String tipo, bool isIngreso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isIngreso ? const Color(0xFF008A3D) : const Color(0xFFFF2E2E),
        borderRadius: BorderRadius.circular(999),
      ),
      child:
          Text(tipo, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    Color color;
    switch (metodo.toLowerCase()) {
      case 'transferencia':
        color = const Color(0xFF1E88E5);
        break;
      case 'efectivo':
        color = const Color(0xFF008A3D);
        break;
      case 'tarjeta':
        color = const Color(0xFF1976D2);
        break;
      case 'mercado pago':
        color = const Color(0xFF1E88E5);
        break;
      default:
        color = const Color(0xFF757575);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(metodo,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  String _formatMonto(double monto) {
    final formatter =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    return formatter.format(monto);
  }
}
