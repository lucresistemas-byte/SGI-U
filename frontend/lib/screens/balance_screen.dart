import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/finanzas/finanzas_bloc.dart';
import '../blocs/finanzas/finanzas_event.dart';
import '../blocs/finanzas/finanzas_state.dart';
import '../widgets/app_scaffold.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/parsers.dart';
import '../models/categoria_movimiento.dart';
import '../widgets/app_button.dart';
import '../widgets/app_data_table.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/section_header.dart';
import '../widgets/tabla_ajustada.dart';
import '../widgets/resultado.dart';
import '../widgets/alto_minimo.dart';
import '../utils/textos_finanzas.dart';
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

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

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
      AppSnackBar.info(context, 'Cargue datos de balance antes de exportar');
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
            SizedBox(width: AppSpacing.espacioEstandar),
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
        AppSnackBar.exito(context, 'Reporte exportado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar dialog
        AppSnackBar.error(context, 'Error al exportar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // En ventanas bajas se desplaza entera (dos filas de tarjetas + tabla).
      body: AltoMinimo(
        minimo: 900,
        child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.espacioPantalla,
            vertical: AppSpacing.espacioEstandar),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              titulo: 'Balance',
              accion: AppButton.primary(
                onPressed: _exportarReportePdf,
                icono: Icons.download,
                child: const Text('Exportar reporte'),
              ),
            ),
            const SizedBox(height: AppSpacing.espacioSeccion),
            _buildFiltrosCard(),
            const SizedBox(height: AppSpacing.espacioSeccion),
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
                    return ErrorState(
                      mensaje: state.message,
                      onReintentar: _cargarBalance,
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
    );
  }

  Widget _buildFiltrosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [
          BoxShadow(
            color: AppColors.textoPrincipal.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rango de Fechas',
              style: AppTypography.tituloTarjeta
                  .copyWith(color: AppColors.textoPrincipal)),
          const SizedBox(height: AppSpacing.espacioEstandar),
          SelectorPeriodo(
            periodo: _periodo,
            hoy: widget.hoy,
            onCambio: (periodo) {
              setState(() => _periodo = periodo);
              _cargarBalance();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasYTabla(Map<String, dynamic> balance) {
    final ingresos = parseDouble(balance['totalIngresos']);
    final egresos = parseDouble(balance['totalEgresos']);
    final margenNeto = parseDouble(balance['margenNeto']);
    final costoTotal = parseDouble(balance['costoTotal']);
    final gananciaReal = parseDouble(balance['gananciaReal']);
    final resultado = balance['resultado'] is Map
        ? Map<String, dynamic>.from(balance['resultado'] as Map)
        : const <String, dynamic>{};
    final gastos = parseDouble(resultado['gastos']);
    final margenGanancia = resultado['margenNetoPorcentaje'] == null
        ? null
        : parseDouble(resultado['margenNetoPorcentaje']);
    final colorMargen = margenNeto >= 0 ? AppColors.marca : AppColors.error;
    const cuando = TextosFinanzas.entreFechas;

    // Dos filas: entró / salió / saldo de caja, y costo / ganancia neta. El
    // saldo de caja y la ganancia neta son más anchos y más altos.
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricaCard(
              key: const Key('balance_ingresos'),
              titulo: 'Total de Ingresos',
              valor: ingresos,
              explicacion: ExplicacionMonto(TextosFinanzas.ingresos(cuando)),
              colorValor: AppColors.marca,
              icon: Icons.trending_up,
              iconBgColor: AppColors.exitoFondo,
              iconColor: AppColors.marca,
            ),
            const SizedBox(width: AppSpacing.espacioSeccion),
            _buildMetricaCard(
              key: const Key('balance_egresos'),
              titulo: 'Total de Egresos',
              valor: egresos,
              explicacion: ExplicacionMonto(TextosFinanzas.egresos(cuando)),
              colorValor: AppColors.error,
              icon: Icons.trending_down,
              iconBgColor: AppColors.error.withValues(alpha: 0.12),
              iconColor: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.espacioSeccion),
            _buildMetricaCard(
              key: const Key('balance_saldo_caja'),
              grande: true,
              titulo: 'Saldo de caja del período',
              valor: margenNeto,
              explicacion: ExplicacionMonto(
                TextosFinanzas.saldoCaja(cuando),
                siNegativo: TextosFinanzas.saldoCajaNegativo,
                negativo: margenNeto < 0,
              ),
              colorValor: colorMargen,
              icon: Icons.wallet_outlined,
              iconBgColor: AppColors.info.withValues(alpha: 0.1),
              iconColor: AppColors.marca,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.espacioEstandar),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricaCard(
              key: const Key('balance_costo'),
              titulo: 'Costo',
              valor: costoTotal,
              explicacion: const ExplicacionMonto(TextosFinanzas.costo),
              colorValor: AppColors.textoTerciario,
              icon: Icons.shopping_basket_outlined,
              iconBgColor: AppColors.fondoAlternativo,
              iconColor: AppColors.textoTerciario,
            ),
            const SizedBox(width: AppSpacing.espacioSeccion),
            _buildMetricaCard(
              key: const Key('balance_ganancia_neta'),
              grande: true,
              titulo: 'Ganancia neta',
              valor: gananciaReal,
              texto: formatPesosConSigno(gananciaReal),
              porcentaje: margenGanancia,
              ayuda: 'Lo que te queda después de pagar los gastos (alquiler, '
                  'luz, sueldos, otros). Las compras de mercadería no se '
                  'restan: su costo ya está en "Costo".',
              explicacion: ExplicacionMonto(
                TextosFinanzas.gananciaNeta(formatPesos(gastos)),
                siNegativo: TextosFinanzas.gananciaNetaNegativa,
                negativo: gananciaReal < 0,
              ),
              colorValor: colorResultado(gananciaReal),
              icon: Icons.show_chart,
              iconBgColor: AppColors.exitoFondo,
              iconColor: AppColors.marca,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.espacioSeccion),
        Expanded(child: _buildTablaMovimientos(balance['movimientos'] ?? [])),
      ],
    );
  }

  /// [grande]: saldo de caja y ganancia neta, más anchas y más altas.
  Widget _buildMetricaCard({
    Key? key,
    required String titulo,
    required double valor,
    required Widget explicacion,
    required Color colorValor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    String? texto,
    double? porcentaje,
    String? ayuda,
    bool grande = false,
  }) {
    return Expanded(
      flex: grande ? 3 : 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth;
          final double circleSize = (cardWidth * 0.22).clamp(36.0, 56.0);
          final double iconSize = circleSize * 0.5;
          final double titleSize = (cardWidth * 0.08).clamp(14.0, 16.0);
          final double moneySize =
              grande ? 30 : (cardWidth * 0.15).clamp(20.0, 28.0);

          return Container(
            key: key,
            constraints: BoxConstraints(minHeight: grande ? 170 : 140),
            padding: EdgeInsets.all(
                grande ? AppSpacing.espacioSeccion : AppSpacing.espacioEstandar),
            decoration: const BoxDecoration(
                color: AppColors.fondoSuperficie,
                borderRadius: AppRadii.bordeTarjeta),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: titleSize,
                              color: AppColors.textoTerciario)),
                    ),
                    if (ayuda != null) ...[
                      const SizedBox(width: AppSpacing.espacioMinimo),
                      AyudaInfo(ayuda),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.espacioChico),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              texto ?? _currencyFormat.format(valor),
                              style: AppTypography.numeroKpi.copyWith(
                                  fontSize: moneySize, color: colorValor),
                            ),
                            if (porcentaje != null) ...[
                              const SizedBox(width: AppSpacing.espacioChico),
                              Text(formatPorcentaje(porcentaje),
                                  style: AppTypography.textoChico.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorValor)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.espacioMedio),
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                          color: iconBgColor, shape: BoxShape.circle),
                      child: Icon(icon, size: iconSize, color: iconColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.espacioChico),
                explicacion,
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
      decoration: const BoxDecoration(
          color: AppColors.fondoSuperficie,
          borderRadius: AppRadii.bordeTarjeta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
            child: Text('Detalle de Movimientos',
                style: AppTypography.tituloTarjeta
                    .copyWith(color: AppColors.textoPrincipal)),
          ),
          Expanded(
            child: AppDataTable(
              altoFilaMaximo: 60,
              separacionColumnas: AppSpacing.espacioSeccion,
              margenHorizontal: AppSpacing.espacioSeccion,
              colorEncabezado: AppColors.fondoAlternativo,
              columnas: const [
                DataColumn(columnWidth: columnaAjustable, label: Text('Fecha/Hora')),
                DataColumn(columnWidth: columnaAjustable, label: Text('Tipo')),
                DataColumn(columnWidth: columnaAjustable, label: Text('Monto')),
                DataColumn(columnWidth: columnaAjustable, label: Text('Costo')),
                DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia')),
                DataColumn(columnWidth: columnaAjustable, label: Text('Método de Pago')),
                DataColumn(columnWidth: columnaAjustable, label: Text('Categoría')),
                DataColumn(columnWidth: columnaFlexible, label: Text('Descripción')),
              ],
              filas: movimientos.map((mov) {
                String tipoRaw = parseString(mov['tipo']);
                String tipoDisplay =
                    tipoRaw.toLowerCase() == 'ingreso' ? 'Ingreso' : 'Egreso';
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
                String descripcion = parseString(mov['descripcion'], '-');

                return DataRow(cells: [
                  DataCell(Text(fechaHora,
                      style: const TextStyle(color: AppColors.textoPrincipal))),
                  DataCell(_buildTipoBadge(tipoDisplay, isIngreso)),
                  DataCell(
                    Text(
                      (isIngreso ? '+ ' : '- ') + _currencyFormat.format(monto),
                      style: TextStyle(
                        color: isIngreso ? AppColors.marcaAcento : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      costo == null ? '—' : _currencyFormat.format(costo),
                      style: const TextStyle(color: AppColors.textoTerciario),
                    ),
                  ),
                  DataCell(
                    Text(
                      ganancia == null
                          ? '—'
                          : (ganancia >= 0 ? '+ ' : '') + _currencyFormat.format(ganancia),
                      style: TextStyle(
                        color: ganancia == null
                            ? AppColors.textoTerciario
                            : ganancia >= 0
                                ? AppColors.marcaAcento
                                : AppColors.error,
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
    return EstadoChip(
      etiqueta: tipo,
      tono: isIngreso ? TonoEstado.exito : TonoEstado.error,
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    final TonoEstado tono;
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        tono = TonoEstado.exito;
        break;
      case 'transferencia':
      case 'mercado pago':
      case 'tarjeta':
        tono = TonoEstado.info;
        break;
      default:
        tono = TonoEstado.neutro;
    }
    return EstadoChip(etiqueta: metodo, tono: tono);
  }
}
