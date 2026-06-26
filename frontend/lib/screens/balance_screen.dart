import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../widgets/side_menu.dart';
import '../services/pdf_service.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({Key? key}) : super(key: key);

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  DateTime _fechaInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaFin = DateTime.now();
  final _formatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _cargarBalance();
  }

  void _cargarBalance() {
    if (_fechaInicio.isAfter(_fechaFin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de inicio no puede ser mayor a la fecha de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<FinanzasBloc>().add(CargarBalance(_fechaInicio, _fechaFin));
  }

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'AR'),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'AR'),
    );
    if (picked != null && picked != _fechaFin) {
      setState(() => _fechaFin = picked);
    }
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
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        totalIngresos: (state.balance['totalIngresos'] ?? 0.0).toDouble(),
        totalEgresos: (state.balance['totalEgresos'] ?? 0.0).toDouble(),
        margenNeto: (state.balance['margenNeto'] ?? 0.0).toDouble(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const SideMenu(rutaActual: '/balance'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Balance',
                        style: TextStyle(fontSize: 54, fontWeight: FontWeight.w400, color: Color(0xFF111111)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportarReportePdf,
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Exportar reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006B3D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                        if (state is BalanceLoading) return const Center(child: CircularProgressIndicator());
                        if (state is BalanceLoaded) return _buildMetricasYTabla(state.balance);
                        if (state is MovimientosError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.message),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _cargarBalance, child: const Text('Reintentar')),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rango de Fechas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFechaField(label: 'Fecha Inicio', fecha: _fechaInicio, onTap: _seleccionarFechaInicio),
              _buildFechaField(label: 'Fecha Fin', fecha: _fechaFin, onTap: _seleccionarFechaFin),
              ElevatedButton(
                onPressed: _cargarBalance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B3D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(120, 48),
                ),
                child: const Text('Filtrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFechaField({required String label, required DateTime fecha, required VoidCallback onTap}) {
    return SizedBox(
      width: 270,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDADADA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatter.format(fecha), style: const TextStyle(color: Color(0xFF111111))),
            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF666666)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasYTabla(Map<String, dynamic> balance) {
    final ingresos = (balance['totalIngresos'] ?? 0.0).toDouble();
    final egresos = (balance['totalEgresos'] ?? 0.0).toDouble();
    final margenNeto = (balance['margenNeto'] ?? 0.0).toDouble();
    final colorMargen = margenNeto >= 0 ? const Color(0xFF006B3D) : const Color(0xFFFF0000);

    return Column(
      children: [
        Row(
          children: [
            _buildMetricaCard(
              titulo: 'Total de Ingresos',
              valor: ingresos,
              colorValor: const Color(0xFF006B3D),
              icon: Icons.trending_up,
              iconBgColor: const Color(0xFFEAF8EF),
              iconColor: const Color(0xFF006B3D),
            ),
            const SizedBox(width: 24),
            _buildMetricaCard(
              titulo: 'Total de Egresos',
              valor: egresos,
              colorValor: const Color(0xFFFF0000),
              icon: Icons.trending_down,
              iconBgColor: const Color(0xFFFFEAEA),
              iconColor: const Color(0xFFFF0000),
            ),
            const SizedBox(width: 24),
            _buildMetricaCard(
              titulo: 'Margen Neto',
              valor: margenNeto,
              colorValor: colorMargen,
              icon: Icons.wallet_outlined,
              iconBgColor: const Color(0xFFEAF1FF),
              iconColor: const Color(0xFF006B3D),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildTablaMovimientos(balance['movimientos'] ?? [])),
      ],
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
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titulo, style: TextStyle(fontSize: titleSize, color: const Color(0xFF666666))),
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
                          style: TextStyle(fontSize: moneySize, fontWeight: FontWeight.bold, color: colorValor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Detalle de Movimientos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 40,
                        horizontalMargin: 24,
                        headingRowHeight: 50,
                        headingRowColor: MaterialStateProperty.resolveWith((_) => const Color(0xFFF6F6F6)),
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        dividerThickness: 1,
                        columns: const [
                          DataColumn(label: Text('Fecha/Hora')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Método de Pago')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Descripción')),
                        ],
                        rows: movimientos.map((mov) {
                          String tipoRaw = mov['tipo'] ?? '';
                          String tipoDisplay = tipoRaw.toLowerCase() == 'ingreso' ? 'Ingreso' : 'Egreso';
                          bool isIngreso = tipoDisplay == 'Ingreso';

                          String metodoRaw = mov['metodoPago']?.toString() ?? '';
                          String metodoDisplay = _parseMetodoPago(metodoRaw);

                          double monto = (mov['monto'] ?? 0.0).toDouble();
                          String fechaHora = _formatFechaHora(mov['fechaHora'] ?? '');
                          String categoria = mov['categoria'] ?? 'Sin categoría';
                          String descripcion = mov['descripcion'] ?? '-';

                          return DataRow(cells: [
                            DataCell(Text(fechaHora, style: const TextStyle(color: Colors.black87))),
                            DataCell(_buildTipoBadge(tipoDisplay, isIngreso)),
                            DataCell(
                              Text(
                                (isIngreso ? '+ ' : '- ') + _formatMonto(monto),
                                style: TextStyle(
                                  color: isIngreso ? const Color(0xFF008A3D) : const Color(0xFFFF2E2E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(_buildMetodoBadge(metodoDisplay)),
                            DataCell(Text(categoria)),
                            DataCell(Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Página 1 de 1', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.chevron_left, color: Colors.grey), onPressed: null),
                IconButton(icon: const Icon(Icons.chevron_right, color: Colors.grey), onPressed: null),
              ],
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
    if (normal.contains('transferencia') || normal == '4') return 'Transferencia';
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
      child: Text(tipo, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(metodo, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  String _formatMonto(double monto) {
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    return formatter.format(monto);
  }
}