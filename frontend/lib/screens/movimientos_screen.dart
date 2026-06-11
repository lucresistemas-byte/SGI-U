// lib/screens/movimientos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../widgets/movimiento_form_dialog.dart';
import '../widgets/side_menu.dart';

class MovimientosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Cargar resumen al iniciar la pantalla (opcional)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanzasBloc>().add(CargarResumen());
      context.read<FinanzasBloc>().add(const CargarMovimientos());
    });
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Row(
        children: [
          SideMenu(rutaActual: '/movimientos'),
          Expanded(child: MovimientosContent()),
        ],
      ),
    );
  }
}

class MovimientosContent extends StatefulWidget {
  const MovimientosContent({Key? key}) : super(key: key);

  @override
  State<MovimientosContent> createState() => _MovimientosContentState();
}

class _MovimientosContentState extends State<MovimientosContent> {
  @override
  void initState() {
    super.initState();
    context.read<FinanzasBloc>().add(const CargarMovimientos());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Movimientos',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const MovimientoFormDialog(),
                  );
                  if (result == true) {
                    context.read<FinanzasBloc>().add(CargarResumen());
                    context.read<FinanzasBloc>().add(const CargarMovimientos());
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Agregar movimiento',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B3D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tarjetas resumen (SIN SCROLL HORIZONTAL)
          BlocBuilder<FinanzasBloc, FinanzasState>(
            builder: (context, state) {
              if (state is ResumenLoading) {
                return const SizedBox(
                  height: 88,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              double ingresosHoy = 0.0;
              double egresosHoy = 0.0;
              double saldoActual = 0.0;
              if (state is ResumenLoaded) {
                ingresosHoy = (state.resumen['ingresosHoy'] ?? 0.0).toDouble();
                egresosHoy = (state.resumen['egresosHoy'] ?? 0.0).toDouble();
                saldoActual = (state.resumen['saldoActual'] ?? 0.0).toDouble();
              }
              final saldoNeto = ingresosHoy - egresosHoy;

              return Row(
                children: [
                  _buildResumenCard('Ingresos Totales (Hoy)', ingresosHoy,
                      const Color(0xFF006B3D)),
                  const SizedBox(width: 16),
                  _buildResumenCard('Egresos Totales (Hoy)', egresosHoy,
                      const Color(0xFFFF2B2B)),
                  const SizedBox(width: 16),
                  _buildResumenCard('Saldo Neto (Hoy)', saldoNeto,
                      const Color(0xFF222222)),
                  const SizedBox(width: 16),
                  _buildResumenCard('Saldo Actual', saldoActual,
                      const Color(0xFF222222)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Tabla de movimientos
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Movimientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<FinanzasBloc, FinanzasState>(
                      builder: (context, state) {
                        if (state is MovimientosLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is MovimientosError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.message),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<FinanzasBloc>().add(const CargarMovimientos());
                                  },
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          );
                        }
                        final movimientos = state is MovimientosLoaded
                            ? state.movimientos
                            : <Map<String, dynamic>>[];
                        if (movimientos.isEmpty) {
                          return const Center(
                            child: Text('No hay movimientos en este período'),
                          );
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowHeight: 42,
                            headingRowColor: MaterialStateProperty.resolveWith(
                                    (_) => const Color(0xFFF7F7F7)),
                            headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 40,
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
                              final monto = mov['monto'] as double;
                              final metodo = mov['metodoPago'] as String;
                              final categoria = mov['categoria'] ?? '';
                              final descripcion = mov['descripcion'] ?? '';
                              return DataRow(cells: [
                                DataCell(Text(mov['fechaHora'])),
                                DataCell(_buildTipoBadge(tipo)),
                                DataCell(
                                  Text(
                                    _formatMonto(monto),
                                    style: TextStyle(
                                      color: monto >= 0
                                          ? const Color(0xFF006B3D)
                                          : const Color(0xFFF53939),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(_buildMetodoBadge(metodo)),
                                DataCell(Text(categoria)),
                                DataCell(Text(descripcion)),
                              ]);
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  // Paginación (placeholder)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Página 1 de 1'),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: null,
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: null,
                        ),
                      ],
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

  // Tarjeta de resumen corregida: altura 88, fuentes más pequeñas, sin scroll
  Widget _buildResumenCard(String titulo, double valor, Color color) {
    return Expanded(
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              _formatMonto(valor),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    final isIngreso = tipo.toLowerCase() == 'ingreso';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isIngreso ? const Color(0xFF0A8F43) : const Color(0xFFF53939),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isIngreso ? 'Ingreso' : 'Egreso',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    Color color;
    switch (metodo.toLowerCase()) {
      case 'transferencia':
        color = const Color(0xFF1E88E5);
        break;
      case 'efectivo':
        color = const Color(0xFF0A8F43);
        break;
      case 'tarjeta':
        color = const Color(0xFF1976D2);
        break;
      default:
        color = const Color(0xFF757575);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        metodo,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatMonto(double monto) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(monto);
  }
}