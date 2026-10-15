package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.FechasInvalidasException;
import com.sgiu_group.sgiu.exceptions.FiltroInvalidoException;
import com.sgiu_group.sgiu.models.dtos.ResultadoPeriodoDTO;
import com.sgiu_group.sgiu.models.dtos.dashboard.*;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class DashboardService {

    /** Cantidad de productos del top de más vendidos. */
    static final int TOP_PRODUCTOS = 5;

    private final VentaRepository ventaRepository;
    private final LineaVentaRepository lineaVentaRepository;
    private final MovFinancieroRepository movFinancieroRepository;
    private final ArticuloStockRepository articuloStockRepository;
    private final PagoVentaRepository pagoVentaRepository;
    private final MetodoPagoRepository metodoPagoRepository;
    private final ResultadoService resultadoService;
    private final EspProductoRepository espProductoRepository;

    public DashboardService(VentaRepository ventaRepository,
                             LineaVentaRepository lineaVentaRepository,
                             MovFinancieroRepository movFinancieroRepository,
                             ArticuloStockRepository articuloStockRepository,
                             PagoVentaRepository pagoVentaRepository,
                             MetodoPagoRepository metodoPagoRepository,
                             ResultadoService resultadoService,
                             EspProductoRepository espProductoRepository) {
        this.ventaRepository = ventaRepository;
        this.lineaVentaRepository = lineaVentaRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.articuloStockRepository = articuloStockRepository;
        this.pagoVentaRepository = pagoVentaRepository;
        this.metodoPagoRepository = metodoPagoRepository;
        this.resultadoService = resultadoService;
        this.espProductoRepository = espProductoRepository;
    }

    public DashboardResponseDTO obtenerDashboard(LocalDate fechaDesde, LocalDate fechaHasta,
                                                  Long metodoPagoId, Long productoId,
                                                  String tipoTransaccion) {
        if (fechaDesde.isAfter(fechaHasta)) {
            throw new FechasInvalidasException("La fecha desde no puede ser mayor que la fecha hasta");
        }

        // Cualquier método existente (también uno desactivado: sus cobros
        // históricos siguen contando).
        if (metodoPagoId != null && !metodoPagoRepository.existsById(metodoPagoId)) {
            throw new FiltroInvalidoException("El método de pago especificado no existe.");
        }
        if (productoId != null && !espProductoRepository.existsById(productoId)) {
            throw new FiltroInvalidoException("El producto especificado no existe.");
        }

        LocalDateTime desde = fechaDesde.atStartOfDay();
        LocalDateTime hasta = fechaHasta.plusDays(1).atStartOfDay();

        DashboardFiltrosDTO filtros = new DashboardFiltrosDTO(
                fechaDesde, fechaHasta, metodoPagoId, productoId, tipoTransaccion);

        // Con método de pago, los montos son solo los cobrados/pagados con él
        // (antes el filtro se validaba pero no se aplicaba).
        BigDecimal ingresos = calcularIngresos(desde, hasta, metodoPagoId, tipoTransaccion);
        BigDecimal egresos = calcularEgresos(desde, hasta, metodoPagoId, tipoTransaccion);
        BigDecimal saldoNeto = calcularSaldoNeto(ingresos, egresos);
        BigDecimal margenNetoPorcentaje = calcularMargenNeto(ingresos, saldoNeto);
        Long cantidadVentas = metodoPagoId == null
                ? calcularCantidadVentas(desde, hasta)
                : Optional.ofNullable(pagoVentaRepository.countVentasConMetodo(desde, hasta, metodoPagoId)).orElse(0L);
        BigDecimal totalVentas = Optional.ofNullable(metodoPagoId == null
                        ? ventaRepository.sumTotalVentasEnRango(desde, hasta)
                        : pagoVentaRepository.sumMontoConMetodo(desde, hasta, metodoPagoId))
                .orElse(BigDecimal.ZERO);
        BigDecimal ticketPromedio = calcularTicketPromedio(totalVentas, cantidadVentas);
        ProductoMasVendidoDTO productoMasVendido = obtenerProductoMasVendido(desde, hasta);
        Long cantidadProductosStockBajo = calcularCantidadStockBajo();

        ResultadoPeriodoDTO resultado;
        if (productoId == null) {
            resultado = resultadoService.calcular(desde, hasta, metodoPagoId);
        } else {
            // Solo lo de ese producto: lo vendido es su ingreso. Los egresos
            // no son de un producto: egresos, saldo y ganancia neta van en
            // null (la app muestra "—").
            ResultadoService.VentasDeProducto delProducto =
                    resultadoService.ventasDeProducto(desde, hasta, metodoPagoId, productoId);
            resultado = resultadoService.calcularDeProducto(delProducto);
            ingresos = delProducto.ventas();
            egresos = null;
            saldoNeto = null;
            margenNetoPorcentaje = null;
            cantidadVentas = delProducto.cantidadVentas();
            ticketPromedio = calcularTicketPromedio(delProducto.ventas(), cantidadVentas);
        }

        DashboardKpisDTO kpis = new DashboardKpisDTO(
                ingresos, egresos, saldoNeto, margenNetoPorcentaje,
                cantidadVentas, ticketPromedio, productoMasVendido,
                cantidadProductosStockBajo);
        kpis.setResultado(resultado);

        DashboardGraficosDTO graficos = new DashboardGraficosDTO();
        graficos.setIngresosVsEgresosPorDia(generarIngresosVsEgresosPorDia(desde, hasta, metodoPagoId));
        graficos.setVentasPorMetodoPago(generarVentasPorMetodoPago(desde, hasta));
        graficos.setTopProductosMasVendidos(generarTopProductos(desde, hasta, productoId));
        graficos.setEvolucionSaldoNeto(generarEvolucionSaldo(desde, hasta, metodoPagoId));
        graficos.setProductosConMenorStock(generarProductosCriticos());
        graficos.setCategoriaMasVendida(obtenerCategoriaMasVendida(desde, hasta));

        boolean hayDatos = ingresos.compareTo(BigDecimal.ZERO) > 0
                || (egresos != null && egresos.compareTo(BigDecimal.ZERO) > 0)
                || cantidadVentas > 0
                || cantidadProductosStockBajo > 0
                || !graficos.getTopProductosMasVendidos().isEmpty()
                || !graficos.getProductosConMenorStock().isEmpty();

        String mensaje = hayDatos
                ? "Dashboard generado correctamente"
                : "No hay datos para el período seleccionado";

        DashboardMetadataDTO metadata = new DashboardMetadataDTO(hayDatos, mensaje);

        return new DashboardResponseDTO(filtros, kpis, graficos, metadata);
    }

    private BigDecimal calcularIngresos(LocalDateTime desde, LocalDateTime hasta,
                                         Long metodoPagoId, String tipoTransaccion) {
        if ("EGRESO".equals(tipoTransaccion)) {
            return BigDecimal.ZERO;
        }
        BigDecimal ingresos = Optional.ofNullable(
                movFinancieroRepository.sumByTipoYMetodoEnRango(desde, hasta, TipoMovimiento.INGRESO, metodoPagoId))
                .orElse(BigDecimal.ZERO);
        return ingresos;
    }

    private BigDecimal calcularEgresos(LocalDateTime desde, LocalDateTime hasta,
                                        Long metodoPagoId, String tipoTransaccion) {
        if ("INGRESO".equals(tipoTransaccion)) {
            return BigDecimal.ZERO;
        }
        BigDecimal egresos = Optional.ofNullable(
                movFinancieroRepository.sumByTipoYMetodoEnRango(desde, hasta, TipoMovimiento.EGRESO, metodoPagoId))
                .orElse(BigDecimal.ZERO);
        return egresos;
    }

    private BigDecimal calcularSaldoNeto(BigDecimal ingresos, BigDecimal egresos) {
        return ingresos.subtract(egresos);
    }

    private BigDecimal calcularMargenNeto(BigDecimal ingresos, BigDecimal saldoNeto) {
        if (ingresos.compareTo(BigDecimal.ZERO) > 0) {
            return saldoNeto.divide(ingresos, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
        }
        return BigDecimal.ZERO;
    }

    private Long calcularCantidadVentas(LocalDateTime desde, LocalDateTime hasta) {
        return Optional.ofNullable(ventaRepository.countVentasEnRango(desde, hasta))
                .orElse(0L);
    }

    private BigDecimal calcularTicketPromedio(BigDecimal totalVentas, Long cantidadVentas) {
        if (cantidadVentas == 0) {
            return BigDecimal.ZERO;
        }
        return totalVentas.divide(BigDecimal.valueOf(cantidadVentas), 2, RoundingMode.HALF_UP);
    }

    private ProductoMasVendidoDTO obtenerProductoMasVendido(LocalDateTime desde, LocalDateTime hasta) {
        List<Object[]> resultados = lineaVentaRepository.findTopProductosVendidos(desde, hasta);
        if (resultados.isEmpty()) {
            return null;
        }
        Object[] top = resultados.get(0);
        Long productoId = ((Number) top[0]).longValue();
        String nombre = (String) top[1];
        Long cantidadVendida = ((Number) top[2]).longValue();
        BigDecimal montoTotal = (BigDecimal) top[3];
        return new ProductoMasVendidoDTO(productoId, nombre, cantidadVendida, montoTotal);
    }

    private CategoriaMasVendidaDTO obtenerCategoriaMasVendida(LocalDateTime desde, LocalDateTime hasta) {
        List<Object[]> resultados = lineaVentaRepository.findTopCategoriasVendidas(desde, hasta);
        if (resultados.isEmpty()) {
            return null;
        }
        Object[] top = resultados.get(0);
        Long categoriaId = ((Number) top[0]).longValue();
        String nombre = (String) top[1];
        Long cantidadVendida = ((Number) top[2]).longValue();
        BigDecimal montoTotal = (BigDecimal) top[3];
        return new CategoriaMasVendidaDTO(categoriaId, nombre, cantidadVendida, montoTotal);
    }

    private Long calcularCantidadStockBajo() {
        return (long) articuloStockRepository.findStockCritico(TipoArticulo.vendibles()).size();
    }

    private List<IngresosEgresosPorDiaDTO> generarIngresosVsEgresosPorDia(
            LocalDateTime desde, LocalDateTime hasta, Long metodoPagoId) {
        List<Object[]> resultados = movFinancieroRepository.findIngresosEgresosPorDia(desde, hasta, metodoPagoId);
        List<IngresosEgresosPorDiaDTO> lista = new ArrayList<>();
        for (Object[] row : resultados) {
            LocalDate fecha = ((java.sql.Date) row[0]).toLocalDate();
            BigDecimal ingresos = Optional.ofNullable((BigDecimal) row[1]).orElse(BigDecimal.ZERO);
            BigDecimal egresos = Optional.ofNullable((BigDecimal) row[2]).orElse(BigDecimal.ZERO);
            lista.add(new IngresosEgresosPorDiaDTO(fecha, ingresos, egresos));
        }
        return lista;
    }

    private List<VentasMetodoPagoDTO> generarVentasPorMetodoPago(
            LocalDateTime desde, LocalDateTime hasta) {
        List<Object[]> resultados = pagoVentaRepository.findVentasAgrupadasPorMetodoPago(desde, hasta);
        List<VentasMetodoPagoDTO> lista = new ArrayList<>();
        for (Object[] row : resultados) {
            String metodo = (String) row[0];
            Long cantidad = ((Number) row[1]).longValue();
            BigDecimal monto = Optional.ofNullable((BigDecimal) row[2]).orElse(BigDecimal.ZERO);
            lista.add(new VentasMetodoPagoDTO(metodo, cantidad, monto));
        }
        return lista;
    }

    private List<ProductoMasVendidoDTO> generarTopProductos(
            LocalDateTime desde, LocalDateTime hasta, Long productoId) {
        List<ProductoMasVendidoDTO> lista = new ArrayList<>();
        for (Object[] row : lineaVentaRepository.findTopProductosConCosto(
                desde, hasta, productoId, PageRequest.of(0, TOP_PRODUCTOS))) {
            lista.add(new ProductoMasVendidoDTO(((Number) row[0]).longValue(), (String) row[1],
                    ((Number) row[2]).longValue(), decimal(row[3]), decimal(row[4])));
        }
        return lista;
    }

    /** Las sumas de precio × cantidad pueden volver como BigDecimal o Double. */
    private static BigDecimal decimal(Object valor) {
        if (valor == null) return BigDecimal.ZERO;
        return valor instanceof BigDecimal b ? b : new BigDecimal(valor.toString());
    }

    private List<EvolucionSaldoDTO> generarEvolucionSaldo(
            LocalDateTime desde, LocalDateTime hasta, Long metodoPagoId) {
        List<Object[]> resultados = movFinancieroRepository.findSaldoNetoAcumuladoPorDia(desde, hasta, metodoPagoId);
        List<EvolucionSaldoDTO> lista = new ArrayList<>();
        BigDecimal runningTotal = BigDecimal.ZERO;
        for (Object[] row : resultados) {
            LocalDate fecha = ((java.sql.Date) row[0]).toLocalDate();
            BigDecimal saldoDia = Optional.ofNullable((BigDecimal) row[1]).orElse(BigDecimal.ZERO);
            runningTotal = runningTotal.add(saldoDia);
            lista.add(new EvolucionSaldoDTO(fecha, runningTotal));
        }
        return lista;
    }

    private List<ProductoStockCriticoDTO> generarProductosCriticos() {
        List<ProductoStockCriticoDTO> lista = new ArrayList<>();
        // En unidades de venta (cajas enteras para la reventa + materia prima).
        for (ArticuloStock a : articuloStockRepository.findStockCritico(TipoArticulo.vendibles())) {
            EspProducto p = a.getEspProducto();
            int stockActual = (int) p.unidadesDeVentaEn(a.getCantidad());
            int stockMinimo = (int) p.unidadesDeVentaEn(a.getStockMinimo());
            String estado = stockActual == 0 ? "AGOTADO" : "BAJO";
            lista.add(new ProductoStockCriticoDTO(p.getId(), p.getNombre(), stockActual, stockMinimo, estado));
        }
        return lista;
    }
}
