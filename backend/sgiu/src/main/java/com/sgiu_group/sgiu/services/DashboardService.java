package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.FechasInvalidasException;
import com.sgiu_group.sgiu.exceptions.FiltroInvalidoException;
import com.sgiu_group.sgiu.models.dtos.dashboard.*;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.*;
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

    private static final List<String> METODOS_PAGO_VALIDOS = List.of(
            "EFECTIVO", "TRANSFERENCIA", "MERCADO_PAGO", "TARJETA");

    private final VentaRepository ventaRepository;
    private final LineaVentaRepository lineaVentaRepository;
    private final MovFinancieroRepository movFinancieroRepository;
    private final ArticuloStockRepository articuloStockRepository;
    private final PagoVentaRepository pagoVentaRepository;

    public DashboardService(VentaRepository ventaRepository,
                             LineaVentaRepository lineaVentaRepository,
                             MovFinancieroRepository movFinancieroRepository,
                             ArticuloStockRepository articuloStockRepository,
                             PagoVentaRepository pagoVentaRepository) {
        this.ventaRepository = ventaRepository;
        this.lineaVentaRepository = lineaVentaRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.articuloStockRepository = articuloStockRepository;
        this.pagoVentaRepository = pagoVentaRepository;
    }

    public DashboardResponseDTO obtenerDashboard(LocalDate fechaDesde, LocalDate fechaHasta,
                                                  String metodoPago, Long productoId,
                                                  String tipoTransaccion) {
        if (fechaDesde.isAfter(fechaHasta)) {
            throw new FechasInvalidasException("La fecha desde no puede ser mayor que la fecha hasta");
        }

        if (metodoPago != null && !METODOS_PAGO_VALIDOS.contains(metodoPago)) {
            throw new FiltroInvalidoException("El método de pago especificado no es válido. Valores permitidos: "
                    + String.join(", ", METODOS_PAGO_VALIDOS));
        }

        LocalDateTime desde = fechaDesde.atStartOfDay();
        LocalDateTime hasta = fechaHasta.plusDays(1).atStartOfDay();

        DashboardFiltrosDTO filtros = new DashboardFiltrosDTO(
                fechaDesde, fechaHasta, metodoPago, productoId, tipoTransaccion);

        BigDecimal ingresos = calcularIngresos(desde, hasta, metodoPago, tipoTransaccion);
        BigDecimal egresos = calcularEgresos(desde, hasta, metodoPago, tipoTransaccion);
        BigDecimal saldoNeto = calcularSaldoNeto(ingresos, egresos);
        BigDecimal margenNetoPorcentaje = calcularMargenNeto(ingresos, saldoNeto);
        Long cantidadVentas = calcularCantidadVentas(desde, hasta);
        BigDecimal totalVentas = Optional.ofNullable(ventaRepository.sumTotalVentasEnRango(desde, hasta))
                .orElse(BigDecimal.ZERO);
        BigDecimal ticketPromedio = calcularTicketPromedio(totalVentas, cantidadVentas);
        ProductoMasVendidoDTO productoMasVendido = obtenerProductoMasVendido(desde, hasta);
        Long cantidadProductosStockBajo = calcularCantidadStockBajo();

        DashboardKpisDTO kpis = new DashboardKpisDTO(
                ingresos, egresos, saldoNeto, margenNetoPorcentaje,
                cantidadVentas, ticketPromedio, productoMasVendido,
                cantidadProductosStockBajo);

        DashboardGraficosDTO graficos = new DashboardGraficosDTO();
        graficos.setIngresosVsEgresosPorDia(generarIngresosVsEgresosPorDia(desde, hasta));
        graficos.setVentasPorMetodoPago(generarVentasPorMetodoPago(desde, hasta));
        graficos.setTopProductosMasVendidos(generarTopProductos(desde, hasta));
        graficos.setEvolucionSaldoNeto(generarEvolucionSaldo(desde, hasta));
        graficos.setProductosConMenorStock(generarProductosCriticos());

        boolean hayDatos = ingresos.compareTo(BigDecimal.ZERO) > 0
                || egresos.compareTo(BigDecimal.ZERO) > 0
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
                                         String metodoPago, String tipoTransaccion) {
        if ("EGRESO".equals(tipoTransaccion)) {
            return BigDecimal.ZERO;
        }
        BigDecimal ingresos = Optional.ofNullable(
                movFinancieroRepository.sumByTipoEnRango(desde, hasta, TipoMovimiento.INGRESO))
                .orElse(BigDecimal.ZERO);
        return ingresos;
    }

    private BigDecimal calcularEgresos(LocalDateTime desde, LocalDateTime hasta,
                                        String metodoPago, String tipoTransaccion) {
        if ("INGRESO".equals(tipoTransaccion)) {
            return BigDecimal.ZERO;
        }
        BigDecimal egresos = Optional.ofNullable(
                movFinancieroRepository.sumByTipoEnRango(desde, hasta, TipoMovimiento.EGRESO))
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

    private Long calcularCantidadStockBajo() {
        return Optional.ofNullable(articuloStockRepository.countProductosConStockCritico())
                .orElse(0L);
    }

    private List<IngresosEgresosPorDiaDTO> generarIngresosVsEgresosPorDia(
            LocalDateTime desde, LocalDateTime hasta) {
        List<Object[]> resultados = movFinancieroRepository.findIngresosEgresosPorDia(desde, hasta);
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
            LocalDateTime desde, LocalDateTime hasta) {
        List<Object[]> resultados = lineaVentaRepository.findTopProductosVendidos(desde, hasta);
        List<ProductoMasVendidoDTO> lista = new ArrayList<>();
        for (Object[] row : resultados) {
            Long productoId = ((Number) row[0]).longValue();
            String nombre = (String) row[1];
            Long cantidadVendida = ((Number) row[2]).longValue();
            BigDecimal montoTotal = (BigDecimal) row[3];
            lista.add(new ProductoMasVendidoDTO(productoId, nombre, cantidadVendida, montoTotal));
        }
        return lista;
    }

    private List<EvolucionSaldoDTO> generarEvolucionSaldo(
            LocalDateTime desde, LocalDateTime hasta) {
        List<Object[]> resultados = movFinancieroRepository.findSaldoNetoAcumuladoPorDia(desde, hasta);
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
        List<Object[]> resultados = articuloStockRepository.findProductosConStockCriticoDetallado();
        List<ProductoStockCriticoDTO> lista = new ArrayList<>();
        for (Object[] row : resultados) {
            Long productoId = ((Number) row[0]).longValue();
            String nombre = (String) row[1];
            Integer stockActual = (Integer) row[2];
            Integer stockMinimo = (Integer) row[3];
            String estado = stockActual == 0 ? "AGOTADO" : "BAJO";
            lista.add(new ProductoStockCriticoDTO(productoId, nombre, stockActual, stockMinimo, estado));
        }
        return lista;
    }
}
