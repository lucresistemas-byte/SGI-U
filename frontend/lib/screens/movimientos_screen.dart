// lib/screens/movimientos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../widgets/movimiento_form_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_colors.dart';
import '../utils/parsers.dart';
import '../widgets/cargando_diferido.dart';
import '../models/categoria_movimiento.dart';
import '../widgets/tabla_ajustada.dart';
import '../utils/numeros.dart';
import '../widgets/resultado.dart';
import '../widgets/alto_minimo.dart';
import '../utils/textos_finanzas.dart';

class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // La carga inicial la hace MovimientosContent en initState
    return const AppScaffold(
      body: MovimientosContent(),
    );
  }
}

class MovimientosContent extends StatefulWidget {
  const MovimientosContent({super.key});

  @override
  State<MovimientosContent> createState() => _MovimientosContentState();
}

class _MovimientosContentState extends State<MovimientosContent> {
  // --- VARIABLES DE PAGINACIÓN ---
  int _paginaActual = 1;
  final int _filasPorPagina = 7;

  @override
  void initState() {
    super.initState();
    context.read<FinanzasBloc>().add(const CargarMovimientos());
  }

  @override
  Widget build(BuildContext context) {
    // En ventanas bajas se desplaza entera (dos filas de tarjetas + tabla).
    return AltoMinimo(
      minimo: 820,
      child: Padding(
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
                    color: Color(0xFF111111)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const MovimientoFormDialog(),
                  );
                  if (result == true) {
                    if (!context.mounted) return;
                    // Si guardó exitosamente, volvemos a la página 1 y recargamos
                    setState(() => _paginaActual = 1);
                    context.read<FinanzasBloc>().add(const CargarMovimientos());
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Agregar movimiento',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdePrincipal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tarjetas resumen
          BlocBuilder<FinanzasBloc, FinanzasState>(
            builder: (context, state) {
              if (state is MovimientosLoading) {
                return const SizedBox(
                    height: 88,
                    child: CargandoDiferido());
              }

              double ingresosHoy = 0.0;
              double egresosHoy = 0.0;
              double saldoActual = 0.0;
              double costoTotalHoy = 0.0;
              double gananciaRealHoy = 0.0;
              double gastosHoy = 0.0;
              double? margenNetoHoy;

              if (state is MovimientosLoaded) {
                ingresosHoy = parseDouble(state.resumen['ingresosHoy']);
                egresosHoy = parseDouble(state.resumen['egresosHoy']);
                saldoActual = parseDouble(state.resumen['saldoActual']);
                costoTotalHoy = parseDouble(state.resumen['costoTotalHoy'] ?? state.resumen['costoTotal']);
                gananciaRealHoy = parseDouble(state.resumen['gananciaRealHoy'] ?? state.resumen['gananciaReal']);
                gastosHoy = parseDouble(state.resumen['gastosHoy']);
                final margen = state.resumen['margenNetoHoy'];
                margenNetoHoy = margen == null ? null : parseDouble(margen);
                // Sin ventas hoy se ve 0 / 0: antes se caía a la suma de
                // todos los movimientos (la historia completa).
              }
              final saldoNeto = ingresosHoy - egresosHoy;

              // Dos filas; el saldo de caja y la ganancia neta son más
              // anchos y más altos.
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResumenCard('Ingresos Totales (Hoy)', ingresosHoy,
                          const Color(0xFF006B3D),
                          explicacion: ExplicacionMonto(
                              TextosFinanzas.ingresos(TextosFinanzas.hoy))),
                      const SizedBox(width: 16),
                      _buildResumenCard('Egresos Totales (Hoy)', egresosHoy,
                          const Color(0xFFFF2B2B),
                          explicacion: ExplicacionMonto(
                              TextosFinanzas.egresos(TextosFinanzas.hoy))),
                      const SizedBox(width: 16),
                      _buildResumenCard('Saldo de caja (Hoy)', saldoNeto,
                          const Color(0xFF222222),
                          grande: true,
                          explicacion: ExplicacionMonto(
                            TextosFinanzas.saldoCaja(TextosFinanzas.hoy),
                            siNegativo: TextosFinanzas.saldoCajaNegativo,
                            negativo: saldoNeto < 0,
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResumenCard('Saldo de caja del mes', saldoActual,
                          const Color(0xFF222222),
                          grande: true,
                          explicacion: ExplicacionMonto(
                            TextosFinanzas.saldoCaja(TextosFinanzas.enElMes),
                            siNegativo: TextosFinanzas.saldoCajaNegativo,
                            negativo: saldoActual < 0,
                          )),
                      const SizedBox(width: 16),
                      _buildResumenCard(
                          'Costo', costoTotalHoy, const Color(0xFF555555),
                          explicacion:
                              const ExplicacionMonto(TextosFinanzas.costo)),
                      const SizedBox(width: 16),
                      _buildResumenCard('Ganancia neta', gananciaRealHoy,
                          colorResultado(gananciaRealHoy),
                          texto: formatPesosConSigno(gananciaRealHoy),
                          porcentaje: margenNetoHoy,
                          grande: true,
                          explicacion: ExplicacionMonto(
                            TextosFinanzas.gananciaNeta(formatPesos(gastosHoy)),
                            siNegativo: TextosFinanzas.gananciaNetaNegativa,
                            negativo: gananciaRealHoy < 0,
                          )),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Tabla de movimientos y Paginación
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('Movimientos',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222))),
                  ),
                  Expanded(
                    child: BlocBuilder<FinanzasBloc, FinanzasState>(
                      builder: (context, state) {
                        if (state is MovimientosLoading) {
                          return const CargandoDiferido();
                        }
                        if (state is MovimientosError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.message),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context
                                      .read<FinanzasBloc>()
                                      .add(const CargarMovimientos()),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          );
                        }

                        final List<dynamic> movimientos =
                            state is MovimientosLoaded ? state.movimientos : [];

                        if (movimientos.isEmpty) {
                          return const Center(
                              child:
                                  Text('No hay movimientos en este período'));
                        }

                        // --- LÓGICA MATEMÁTICA DE PAGINACIÓN ---
                        int totalPaginas =
                            (movimientos.length / _filasPorPagina).ceil();
                        if (totalPaginas == 0) totalPaginas = 1;

                        // Seguro por si borramos elementos y la página actual ya no existe
                        if (_paginaActual > totalPaginas) {
                          _paginaActual = totalPaginas;
                        }

                        int startIndex = (_paginaActual - 1) * _filasPorPagina;
                        int endIndex = startIndex + _filasPorPagina;
                        if (endIndex > movimientos.length) {
                          endIndex = movimientos.length;
                        }

                        // Cortamos la lista para mostrar solo las 7 filas correspondientes
                        List<dynamic> movimientosPaginados =
                            movimientos.sublist(startIndex, endIndex);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TablaAjustada(
                                tabla: DataTable(
                                  columnSpacing: 24,
                                  horizontalMargin: 24,
                                  headingRowHeight: 42,
                                  headingRowColor:
                                      WidgetStateProperty.resolveWith(
                                          (_) => const Color(0xFFF7F7F7)),
                                  headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87),
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 48,
                                  dividerThickness: 1,
                                  columns: const [
                                    DataColumn(columnWidth: columnaAjustable, label: Text('Fecha/Hora')),
                                    DataColumn(columnWidth: columnaAjustable, label: Text('Tipo')),
                                    DataColumn(columnWidth: columnaAjustable, label: Text('Monto')),
                                    DataColumn(columnWidth: columnaAjustable, label: Text('Costo')),
                                    DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia')),
                                    DataColumn(
                                        columnWidth: columnaAjustable, label: Text('Método de Pago')),
                                    DataColumn(columnWidth: columnaAjustable, label: Text('Categoría')),
                                    DataColumn(columnWidth: columnaFlexible, label: Text('Descripción')),
                                  ],
                                  // Usamos la lista cortada (movimientosPaginados) en vez de la original
                                  rows: movimientosPaginados
                                      .map((dynamic item) {
                                    Map<String, dynamic> mov = item is Map
                                        ? Map<String, dynamic>.from(item)
                                        : {};

                                    String tipoRaw =
                                        mov['tipo']?.toString() ?? '';
                                    String tipoDisplay =
                                        tipoRaw.toLowerCase() == 'ingreso'
                                            ? 'Ingreso'
                                            : 'Egreso';
                                    bool isIngreso =
                                        tipoDisplay == 'Ingreso';

                                    double monto =
                                        parseDouble(mov['monto']);
                                    // Null en los egresos: un gasto no
                                    // tiene costo ni ganancia.
                                    final double? costo = mov['costo'] == null
                                        ? null
                                        : parseDouble(mov['costo']);
                                    final double? ganancia =
                                        mov['ganancia'] == null
                                            ? null
                                            : parseDouble(mov['ganancia']);

                                    String metodoRaw =
                                        mov['metodoPago']?.toString() ??
                                            '';
                                    String metodoDisplay =
                                        _parseMetodoPago(metodoRaw);

                                    String fechaHora = _formatFechaHora(
                                        mov['fechaHora']?.toString() ??
                                            '');
                                    String categoria =
                                        CategoriaMovimiento.etiquetaDe(
                                            mov['categoria']
                                                ?.toString());
                                    String descripcion =
                                        mov['descripcion']?.toString() ??
                                            '-';

                                    return DataRow(cells: [
                                      DataCell(Text(fechaHora)),
                                      DataCell(_buildTipoBadge(
                                          tipoDisplay, isIngreso)),
                                      DataCell(
                                        Text(
                                          (isIngreso ? '+ ' : '- ') +
                                              _formatMonto(monto),
                                          style: TextStyle(
                                            color: isIngreso
                                                ? const Color(0xFF006B3D)
                                                : const Color(0xFFF53939),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          costo == null
                                              ? '—'
                                              : _formatMonto(costo),
                                          style: const TextStyle(
                                              color: Color(0xFF666666)),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          ganancia == null
                                              ? '—'
                                              : (ganancia >= 0 ? '+ ' : '') +
                                                  _formatMonto(ganancia),
                                          style: TextStyle(
                                            color: ganancia == null
                                                ? const Color(0xFF666666)
                                                : ganancia >= 0
                                                    ? const Color(0xFF006B3D)
                                                    : const Color(0xFFF53939),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(_buildMetodoBadge(
                                          metodoDisplay)),
                                      DataCell(Text(categoria)),
                                      DataCell(Text(descripcion,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis)),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                            // Footer de Paginación Dinámico
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: Colors.grey.shade200))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Página $_paginaActual de $totalPaginas',
                                      style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(Icons.chevron_left,
                                        color: _paginaActual > 1
                                            ? const Color(0xFF006B3D)
                                            : Colors.grey),
                                    onPressed: _paginaActual > 1
                                        ? () {
                                            setState(() => _paginaActual--);
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right,
                                        color: _paginaActual < totalPaginas
                                            ? const Color(0xFF006B3D)
                                            : Colors.grey),
                                    onPressed: _paginaActual < totalPaginas
                                        ? () {
                                            setState(() => _paginaActual++);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// [texto] reemplaza el monto formateado (p. ej. la ganancia con signo).
  /// [grande]: saldo de caja y ganancia neta, más anchas y más altas.
  Widget _buildResumenCard(String titulo, double valor, Color color,
      {String? texto,
      double? porcentaje,
      required Widget explicacion,
      bool grande = false}) {
    return Expanded(
      flex: grande ? 3 : 2,
      child: Container(
        key: Key('movimientos_tarjeta_$titulo'),
        constraints: BoxConstraints(minHeight: grande ? 130 : 110),
        padding: EdgeInsets.all(grande ? 18 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    texto ?? _formatMonto(valor),
                    style: TextStyle(
                        fontSize: grande ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  if (porcentaje != null) ...[
                    const SizedBox(width: 8),
                    Text(formatPorcentaje(porcentaje),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            explicacion,
          ],
        ),
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
    return raw.isNotEmpty ? raw : 'N/A';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isIngreso ? const Color(0xFF008A3D) : const Color(0xFFFF2E2E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tipo,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(metodo,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  String _formatMonto(double monto) {
    final formatter =
        NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);
    return formatter.format(monto);
  }
}
