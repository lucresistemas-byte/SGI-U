// lib/screens/balance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../widgets/side_menu.dart';

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
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Balance',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF111111),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Exportar reporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006B3D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          minimumSize: const Size(250, 56),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tarjeta de filtros
                  _buildFiltrosCard(),
                  const SizedBox(height: 24),
                  // Tarjetas de métricas + tabla
                  Expanded(
                    child: BlocBuilder<FinanzasBloc, FinanzasState>(
                      builder: (context, state) {
                        if (state is BalanceLoading) {
                          return const Center(child: CircularProgressIndicator());
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
                                  child: const Text('Reintentar'),
                                ),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rango de Fechas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFechaField(label: 'Fecha Inicio', fecha: _fechaInicio, onTap: _seleccionarFechaInicio),
              const SizedBox(width: 16),
              _buildFechaField(label: 'Fecha Fin', fecha: _fechaFin, onTap: _seleccionarFechaFin),
              const SizedBox(width: 16),
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
    final ingresos = (balance['ingresos'] ?? 0.0).toDouble();
    final egresos = (balance['egresos'] ?? 0.0).toDouble();
    final margenNeto = ingresos - egresos;
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
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatter.format(valor),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: colorValor)),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(40)),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaMovimientos(List<dynamic> movimientos) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Detalle de Movimientos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 50,
                headingRowColor: MaterialStateProperty.resolveWith((_) => const Color(0xFFF6F6F6)),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w600),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
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
                  final tipo = mov['tipo'] as String;
                  final monto = (mov['monto'] as num).toDouble();
                  final metodo = mov['metodoPago'] as String;
                  final categoria = mov['categoria'] ?? '';
                  final descripcion = mov['descripcion'] ?? '';
                  return DataRow(cells: [
                    DataCell(Text(mov['fechaHora'])),
                    DataCell(_buildTipoBadge(tipo)),
                    DataCell(Text(_formatMonto(monto),
                        style: TextStyle(
                          color: tipo.toLowerCase() == 'ingreso' ? const Color(0xFF008A3D) : const Color(0xFFFF2E2E),
                          fontWeight: FontWeight.w500,
                        ))),
                    DataCell(_buildMetodoBadge(metodo)),
                    DataCell(Text(categoria)),
                    DataCell(Text(descripcion)),
                  ]);
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Página 1 de 1'),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: null),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    final isIngreso = tipo.toLowerCase() == 'ingreso';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isIngreso ? const Color(0xFF008A3D) : const Color(0xFFFF2E2E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(isIngreso ? 'Ingreso' : 'Egreso', style: const TextStyle(color: Colors.white, fontSize: 12)),
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