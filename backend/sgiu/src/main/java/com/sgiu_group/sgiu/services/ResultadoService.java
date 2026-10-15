package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ResultadoPeriodoDTO;
import com.sgiu_group.sgiu.models.entities.CategoriaMovimiento;
import com.sgiu_group.sgiu.repositories.LineaVentaRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Calcula el {@link ResultadoPeriodoDTO} de [desde, hasta). El mismo cálculo
 * para Inicio y Ganancias, así los números coinciden en las dos pantallas.
 */
@Service
@Transactional(readOnly = true)
public class ResultadoService {

    private final VentaRepository ventaRepository;
    private final LineaVentaRepository lineaVentaRepository;
    private final PagoVentaRepository pagoVentaRepository;
    private final MovFinancieroRepository movFinancieroRepository;

    public ResultadoService(VentaRepository ventaRepository,
                            LineaVentaRepository lineaVentaRepository,
                            PagoVentaRepository pagoVentaRepository,
                            MovFinancieroRepository movFinancieroRepository) {
        this.ventaRepository = ventaRepository;
        this.lineaVentaRepository = lineaVentaRepository;
        this.pagoVentaRepository = pagoVentaRepository;
        this.movFinancieroRepository = movFinancieroRepository;
    }

    /**
     * @param metodoPagoId null = todos. Con un método, las ventas son lo
     *        cobrado con él y el costo de cada venta se toma en proporción a
     *        lo cobrado con él (en un pago mixto, como en el balance).
     */
    public ResultadoPeriodoDTO calcular(LocalDateTime desde, LocalDateTime hasta, Long metodoPagoId) {
        BigDecimal ventas;
        BigDecimal costo;
        if (metodoPagoId == null) {
            ventas = nz(ventaRepository.sumTotalVentasEnRango(desde, hasta));
            costo = nz(lineaVentaRepository.sumCostoEnRango(desde, hasta));
        } else {
            ventas = nz(pagoVentaRepository.sumMontoConMetodo(desde, hasta, metodoPagoId));
            costo = costoProporcional(pagoVentaRepository.findCobrosConMetodo(desde, hasta, metodoPagoId));
        }

        BigDecimal otrosIngresos = nz(movFinancieroRepository.sumIngresosSinVenta(desde, hasta, metodoPagoId));
        BigDecimal gastos = BigDecimal.ZERO;
        BigDecimal compras = BigDecimal.ZERO;
        for (Object[] fila : movFinancieroRepository.sumEgresosPorCategoria(desde, hasta, metodoPagoId)) {
            BigDecimal monto = decimal(fila[1]);
            if (CategoriaMovimiento.COMPRA.name().equals(fila[0])) {
                compras = compras.add(monto);
            } else {
                gastos = gastos.add(monto);
            }
        }

        BigDecimal bruta = ventas.subtract(costo);
        BigDecimal neta = bruta.add(otrosIngresos).subtract(gastos);
        return new ResultadoPeriodoDTO(ventas, costo, bruta, porcentaje(bruta, ventas),
                otrosIngresos, gastos, compras, neta, porcentaje(neta, ventas));
    }

    /** Filas [ventaId, cobrado con el método, total de la venta]. */
    private BigDecimal costoProporcional(List<Object[]> cobros) {
        if (cobros.isEmpty()) return BigDecimal.ZERO;
        Map<Long, BigDecimal> costoPorVenta = new HashMap<>();
        for (Object[] fila : lineaVentaRepository.sumarCostoPorVenta(
                cobros.stream().map(f -> ((Number) f[0]).longValue()).toList())) {
            costoPorVenta.put(((Number) fila[0]).longValue(), decimal(fila[1]));
        }
        BigDecimal costo = BigDecimal.ZERO;
        for (Object[] fila : cobros) {
            BigDecimal total = decimal(fila[2]);
            BigDecimal costoVenta = costoPorVenta.getOrDefault(((Number) fila[0]).longValue(), BigDecimal.ZERO);
            if (total.signum() == 0) continue;
            costo = costo.add(costoVenta.multiply(decimal(fila[1])).divide(total, 2, RoundingMode.HALF_UP));
        }
        return costo;
    }

    private static BigDecimal porcentaje(BigDecimal parte, BigDecimal ventas) {
        if (ventas.signum() == 0) return null;
        return parte.multiply(BigDecimal.valueOf(100)).divide(ventas, 2, RoundingMode.HALF_UP);
    }

    private static BigDecimal nz(BigDecimal valor) {
        return valor != null ? valor : BigDecimal.ZERO;
    }

    /** Las sumas de precio × cantidad pueden volver como BigDecimal o Double. */
    private static BigDecimal decimal(Object valor) {
        if (valor == null) return BigDecimal.ZERO;
        return valor instanceof BigDecimal b ? b : new BigDecimal(valor.toString());
    }
}
