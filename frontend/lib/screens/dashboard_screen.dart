// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_scaffold.dart';
import '../services/api_service.dart';
import '../models/dashboard_models.dart';
import '../models/metodo_pago.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_data_table.dart';
import '../widgets/cargando_diferido.dart';
import '../widgets/estado_seccion.dart';
import '../widgets/estado_chip.dart';
import '../navigation/ir_a_seccion.dart';
import '../navigation/seccion.dart';
import '../utils/numeros.dart';
import '../utils/periodo.dart';
import '../utils/textos_finanzas.dart';
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
  /// Tipo de producto del filtro (ELABORADO, ...); null = todos.
  String? _filtroTipo;

  /// Tipos que se venden en el POS: (valor del backend, texto).
  static const _tiposProducto = [
    ('ELABORADO', 'Elaborado'),
    ('REVENTA', 'Reventa'),
    ('REVENTA_MATERIA_PRIMA', 'Reventa + materia prima'),
    ('PAQUETE', 'Paquete'),
  ];

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
        tipoProducto: _filtroTipo,
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
          ? const CargandoDiferido(color: AppColors.marcaAcento)
          : _errorMessage != null
              ? ErrorState(
                  mensaje: 'Hubo un problema: $_errorMessage',
                  onReintentar: _cargarDatos,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.espacioPantalla),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 3,
                        child: _isLoading
                            ? const LinearProgressIndicator(color: AppColors.marcaAcento)
                            : null,
                      ),
                      _buildCabecera(),
                      const SizedBox(height: AppSpacing.espacioPantalla),
                      _buildTarjetasFinancieras(),
                      const SizedBox(height: AppSpacing.espacioPantalla),
                      _buildMetricasComerciales(),
                      const SizedBox(height: AppSpacing.espacioPantalla),
                      _buildAlertasOperativas(),
                    ],
                  ),
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
              spacing: AppSpacing.espacioMedio,
              runSpacing: AppSpacing.espacioChico,
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
                _buildTipoProductoDropdown(),
              ],
            );

            final titulo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SGI-U - Tablero de Control',
                  style: AppTypography.tituloPantalla
                      .copyWith(color: AppColors.textoPrincipal),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Resumen Ejecutivo',
                      style: AppTypography.subtitulo
                          .copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(width: AppSpacing.espacioChico),
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.textoTerciario),
                  ],
                ),
              ],
            );

            if (constraints.maxWidth < 950) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titulo,
                  const SizedBox(height: AppSpacing.espacioEstandar),
                  filtros,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: titulo),
                const SizedBox(width: AppSpacing.espacioEstandar),
                Expanded(flex: 7, child: filtros),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.espacioEstandar),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.marcaAcento, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.espacioChico),
            Expanded(
              child: Text(
                'Visualiza la salud financiera y el desempeño de tu negocio en el período seleccionado.',
                style: AppTypography.textoChico
                    .copyWith(color: AppColors.textoTerciario),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.espacioMedio, vertical: AppSpacing.espacioMinimo),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        border: Border.all(color: AppColors.bordeSuave),
        borderRadius: AppRadii.bordeChico,
      ),
      child: DropdownButton<int?>(
        key: const Key('dashboard_filtro_metodo_pago'),
        value: seleccion,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down,
            size: 18, color: AppColors.textoSecundario),
        style: AppTypography.textoChico
            .copyWith(color: AppColors.textoPrincipal, fontWeight: FontWeight.w500),
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

  Widget _buildTipoProductoDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.espacioMedio, vertical: AppSpacing.espacioMinimo),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        border: Border.all(color: AppColors.bordeSuave),
        borderRadius: AppRadii.bordeChico,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 10),
          DropdownButton<String?>(
            key: const Key('dashboard_filtro_tipo'),
            value: _filtroTipo,
            underline: const SizedBox.shrink(),
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 18, color: AppColors.textoSecundario),
            style: AppTypography.textoChico.copyWith(
                color: AppColors.textoPrincipal, fontWeight: FontWeight.w500),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos los tipos')),
              for (final (valor, texto) in _tiposProducto)
                DropdownMenuItem<String?>(value: valor, child: Text(texto)),
            ],
            onChanged: (value) {
              setState(() => _filtroTipo = value);
              _cargarDatos();
            },
          ),
        ],
      ),
    );
  }

  // --- BLOQUE 1: SALUD FINANCIERA ---
  /// Con un tipo de producto elegido, los gastos (Egresos, Saldo de caja y
  /// Ganancia neta) siguen siendo de todo el negocio y lo aclaran.
  List<String> get _notaTipo => _filtroTipo == null ? const [] : const [TextosFinanzas.noSeFiltraPorTipo];

  Widget _buildTarjetasFinancieras() {
    final kpis = _dashboardData!.kpis;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    const cuando = TextosFinanzas.entreFechas;
    final saldo = kpis.saldoNeto ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Me está quedando plata?',
          style: AppTypography.subtitulo
              .copyWith(color: AppColors.marcaAcento),
        ),
        const SizedBox(height: AppSpacing.espacioEstandar),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildStandardCard(
                key: const Key('dashboard_ingresos'),
                titulo: 'Ingresos del Período',
                monto: formatter.format(kpis.ingresosPeriodo),
                explicacion: ExplicacionMonto(_filtroTipo == null
                    ? TextosFinanzas.ingresos(cuando)
                    : TextosFinanzas.ingresosDeTipo(cuando)),
                montoColor: AppColors.marcaAcento,
              ),
            ),
            const SizedBox(width: AppSpacing.espacioGrande),
            Expanded(
              flex: 2,
              child: _buildStandardCard(
                key: const Key('dashboard_egresos'),
                titulo: 'Egresos del Período',
                monto: formatter.format(kpis.egresosPeriodo ?? 0),
                explicacion: ExplicacionMonto(TextosFinanzas.egresos(cuando), extras: _notaTipo),
                montoColor: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.espacioGrande),
            Expanded(
              flex: 3,
              child: _buildSaldoCard(
                titulo: 'Saldo de caja del período',
                monto: formatter.format(saldo),
                explicacion: ExplicacionMonto(
                  TextosFinanzas.saldoCaja(cuando),
                  siNegativo: TextosFinanzas.saldoCajaNegativo,
                  negativo: saldo < 0,
                  extras: _notaTipo,
                  color: AppColors.sobreMarca.withValues(alpha: 0.7),
                  colorNegativo: AppColors.alertaFondo,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.espacioGrande),
        _buildTarjetasGanancia(),
      ],
    );
  }

  /// Costo de lo vendido, ganancia bruta y ganancia neta, con el mismo
  /// estilo que las tarjetas de arriba: pesos grandes y el % chico al lado.
  Widget _buildTarjetasGanancia() {
    final r = _dashboardData!.kpis.resultado;
    final neta = r.gananciaNeta ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildStandardCard(
            key: const Key('dashboard_costo'),
            titulo: 'Costo',
            monto: formatPesos(r.costoVendido),
            explicacion: const ExplicacionMonto(TextosFinanzas.costo),
            montoColor: AppColors.textoSecundario,
          ),
        ),
        const SizedBox(width: AppSpacing.espacioGrande),
        Expanded(
          flex: 2,
          child: _buildStandardCard(
            key: const Key('dashboard_ganancia'),
            titulo: 'Ganancia',
            monto: formatPesosConSigno(r.gananciaBruta),
            porcentaje: r.margenBrutoPorcentaje,
            explicacion: ExplicacionMonto(
              TextosFinanzas.ganancia,
              siNegativo: TextosFinanzas.gananciaNegativa,
              negativo: r.gananciaBruta < 0,
            ),
            montoColor: colorResultado(r.gananciaBruta),
          ),
        ),
        const SizedBox(width: AppSpacing.espacioGrande),
        Expanded(
          flex: 3,
          child: _buildStandardCard(
            key: const Key('dashboard_ganancia_neta'),
            grande: true,
            titulo: 'Ganancia neta',
            ayuda: 'Lo que te queda después de pagar los gastos: alquiler, luz, '
                'sueldos y otros. Las compras de mercadería no se restan acá: '
                'su costo ya está en "Costo" cuando vendés lo que hiciste con ella.',
            monto: formatPesosConSigno(neta),
            porcentaje: r.margenNetoPorcentaje,
            explicacion: ExplicacionMonto(
              TextosFinanzas.gananciaNeta(formatPesos(r.gastos ?? 0)),
              siNegativo: TextosFinanzas.gananciaNetaNegativa,
              negativo: neta < 0,
              extras: _notaTipo,
            ),
            montoColor: colorResultado(neta),
          ),
        ),
      ],
    );
  }

  /// [grande]: Ganancia neta, más alta y con más aire para la explicación.
  Widget _buildStandardCard({
    Key? key,
    required String titulo,
    required String monto,
    required Widget explicacion,
    required Color montoColor,
    double? porcentaje,
    String? ayuda,
    bool grande = false,
  }) {
    return Container(
      key: key,
      constraints: BoxConstraints(minHeight: grande ? 230 : 0),
      padding: EdgeInsets.all(grande ? 28 : AppSpacing.espacioSeccion),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [BoxShadow(color: AppColors.textoPrincipal.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(titulo,
                    style: AppTypography.textoChico.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPrincipal)),
              ),
              if (ayuda != null) ...[
                const SizedBox(width: 6),
                AyudaInfo(ayuda),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.espacioMedio),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(monto, style: (grande ? AppTypography.marca : AppTypography.tituloPantalla).copyWith(color: montoColor)),
                if (porcentaje != null) ...[
                  const SizedBox(width: AppSpacing.espacioChico),
                  Text(formatPorcentaje(porcentaje),
                      style: AppTypography.textoChico.copyWith(
                          fontWeight: FontWeight.w600, color: montoColor)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          explicacion,
        ],
      ),
    );
  }

  /// Saldo de caja del período: más grande que las demás.
  Widget _buildSaldoCard({required String titulo, required String monto, required Widget explicacion}) {
    return Container(
      key: const Key('dashboard_saldo_caja'),
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.marcaActiva,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [BoxShadow(color: AppColors.marcaActiva.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: AppTypography.textoChico.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.sobreMarca.withValues(alpha: 0.7))),
          const SizedBox(height: AppSpacing.espacioMedio),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(monto, style: AppTypography.marca.copyWith(color: AppColors.sobreMarca)),
          ),
          const SizedBox(height: 10),
          explicacion,
        ],
      ),
    );
  }

  // --- BLOQUE 2: MOTOR COMERCIAL ---
  Widget _buildMetricasComerciales() {
    final kpis = _dashboardData!.kpis;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        final enColumna = constraints.maxWidth < 950;
        final tarjetas = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMetricCard(
                key: const Key('dashboard_cantidad_ventas'),
                titulo: 'Cantidad de Ventas',
                valor: kpis.cantidadVentas.toString(),
                explicacion: TextosFinanzas.cantidadVentas(TextosFinanzas.entreFechas,
                    deTipo: _filtroTipo != null),
              ),
            ),
            const SizedBox(width: AppSpacing.espacioGrande),
            Expanded(
              child: _buildMetricCard(
                key: const Key('dashboard_ticket'),
                titulo: 'Ticket Promedio',
                valor: formatter.format(kpis.ticketPromedio),
                explicacion: TextosFinanzas.ticketPromedio,
              ),
            ),
          ],
        );

        final chart = _buildChartPlaceholder();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo se está moviendo mi negocio?',
              style: AppTypography.subtitulo.copyWith(color: AppColors.marcaAcento),
            ),
            const SizedBox(height: AppSpacing.espacioEstandar),
            if (enColumna) ...[
              tarjetas,
              const SizedBox(height: AppSpacing.espacioGrande),
              chart,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: tarjetas),
                  const SizedBox(width: AppSpacing.espacioGrande),
                  Expanded(flex: 6, child: chart),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({Key? key, required String titulo, required String valor, required String explicacion}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.espacioSeccion, horizontal: AppSpacing.espacioEstandar),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [BoxShadow(color: AppColors.textoPrincipal.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(titulo,
              style: AppTypography.textoChico.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPrincipal)),
          const SizedBox(height: AppSpacing.espacioEstandar),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valor, style: AppTypography.marca.copyWith(color: AppColors.textoPrincipal)),
          ),
          const SizedBox(height: AppSpacing.espacioChico),
          ExplicacionMonto(explicacion, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 185,
      padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [BoxShadow(color: AppColors.textoPrincipal.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Evolución del Dinero',
                    style: AppTypography.textoChico.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPrincipal)),
              ),
              const SizedBox(width: AppSpacing.espacioChico),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.espacioMedio, vertical: 6),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.bordeSuave),
                    borderRadius: AppRadii.bordeChico),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Diario', style: AppTypography.etiqueta),
                    SizedBox(width: AppSpacing.espacioMinimo),
                    Icon(Icons.keyboard_arrow_down, size: 14),
                  ],
                ),
              )
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bar_chart, size: 48, color: AppColors.textoInactivo),
                const SizedBox(height: AppSpacing.espacioChico),
                Text('Gráfico de barras próximamente...',
                    style: AppTypography.texto.copyWith(color: AppColors.textoTerciario)),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final enColumna = constraints.maxWidth < 950;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alertas Operativas (El Día a Día)',
              style: AppTypography.subtitulo.copyWith(color: AppColors.marcaAcento),
            ),
            const SizedBox(height: AppSpacing.espacioEstandar),
            if (enColumna) ...[
              _buildStockCriticoCard(),
              const SizedBox(height: AppSpacing.espacioGrande),
              _buildTopProductosCard(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStockCriticoCard()),
                  const SizedBox(width: AppSpacing.espacioGrande),
                  Expanded(child: _buildTopProductosCard()),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildStockCriticoCard() {
    final listaStock = _dashboardData!.graficos.productosConMenorStock;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [BoxShadow(color: AppColors.textoPrincipal.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Stock Crítico - Reposición Urgente',
              style: AppTypography.textoChico.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPrincipal)),
          const Divider(height: 32, color: AppColors.fondoAlternativo),
          AppDataTable(
            ajustarAncho: false,
            separacionColumnas: AppSpacing.espacioEstandar,
            margenHorizontal: 0,
            columnas: const [
              DataColumn(columnWidth: columnaFlexible, label: Text('Producto')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Stock Actual')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Stock Mínimo')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Estado')),
            ],
            filas: listaStock.isEmpty
                ? [
                    const DataRow(cells: [
                      DataCell(Text('Todo en orden')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ])
                  ]
                : listaStock.map((p) {
                    final agotado = p.estado == 'AGOTADO' || p.stockActual == 0;
                    return DataRow(
                      cells: [
                        DataCell(Text(p.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text('${p.stockActual} un.',
                            style: TextStyle(
                                color: agotado ? AppColors.error : AppColors.alerta,
                                fontWeight: FontWeight.bold))),
                        DataCell(Text('${p.stockMinimo} un.')),
                        DataCell(EstadoChip(
                          etiqueta: p.estado,
                          tono: agotado ? TonoEstado.error : TonoEstado.alerta,
                        )),
                      ],
                    );
                  }).toList(),
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          Center(
            child: AppButton.ghost(
              key: const Key('dashboard_ver_inventario'),
              onPressed: () => IrASeccion.de(context)?.call(Seccion.catalogo),
              icono: Icons.arrow_forward,
              child: const Text('Ver inventario completo'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopProductosCard() {
    final listaTop = _dashboardData!.graficos.topProductosMasVendidos;
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    int ranking = 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.espacioSeccion),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficie,
        borderRadius: AppRadii.bordeTarjeta,
        boxShadow: [BoxShadow(color: AppColors.textoPrincipal.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Top Productos Más Vendidos',
              style: AppTypography.textoChico.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPrincipal)),
          const Divider(height: 32, color: AppColors.fondoAlternativo),
          AppDataTable(
            key: const Key('dashboard_top_productos'),
            ajustarAncho: false,
            separacionColumnas: AppSpacing.espacioEstandar,
            margenHorizontal: 0,
            columnas: const [
              DataColumn(columnWidth: columnaAjustable, label: Text('#')),
              DataColumn(columnWidth: columnaFlexible, label: Text('Producto')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Cant. Vendida')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Monto Generado')),
              DataColumn(columnWidth: columnaAjustable, label: Text('Ganancia')),
            ],
            filas: listaTop.isEmpty
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
                    final barWidth = ranking == 1 ? 1.0 : (ranking == 2 ? 0.8 : 0.5);
                    final fila = _buildTopRow(ranking.toString(), p.nombre, p.cantidadVendida.toString(), formatter.format(p.montoTotal), barWidth, p.ganancia);
                    ranking++;
                    return fila;
                  }).toList(),
          ),
          const SizedBox(height: AppSpacing.espacioEstandar),
          Center(
            child: AppButton.ghost(
              key: const Key('dashboard_ver_reporte'),
              onPressed: () => IrASeccion.de(context)?.call(Seccion.balance),
              icono: Icons.arrow_forward,
              child: const Text('Ver reporte completo'),
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
            const SizedBox(width: AppSpacing.espacioChico),
            Container(
              height: 6,
              width: 40 * barWidth,
              decoration: const BoxDecoration(
                  color: AppColors.marcaAcento, borderRadius: AppRadii.bordeMinimo),
            ),
          ],
        )),
        DataCell(Text(
          ganancia == null ? '-' : formatPesosConSigno(ganancia),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ganancia == null ? AppColors.textoPrincipal : colorResultado(ganancia),
          ),
        )),
      ],
    );
  }
}
