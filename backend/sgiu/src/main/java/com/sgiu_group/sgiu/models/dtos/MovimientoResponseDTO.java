package com.sgiu_group.sgiu.models.dtos;

import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record MovimientoResponseDTO(
    Long id,
    String tipo,
    BigDecimal monto,
    String metodoPago,
    String categoria,
    String descripcion,
    LocalDateTime fechaHora,
    BigDecimal costo,
    BigDecimal ganancia
) {
    public MovimientoResponseDTO(
            Long id,
            String tipo,
            BigDecimal monto,
            String metodoPago,
            String categoria,
            String descripcion,
            LocalDateTime fechaHora
    ) {
        this(id, tipo, monto, metodoPago, categoria, descripcion, fechaHora, BigDecimal.ZERO, monto);
    }

    /** Movimiento sin venta asociada (alta manual). */
    public static MovimientoResponseDTO fromEntity(MovFinanciero mov) {
        return fromEntity(mov, null);
    }

    /**
     * @param costoVenta costo congelado de la venta del movimiento (de
     *        LineaVentaRepository.sumarCostoPorVenta); se ignora si el movimiento
     *        no viene de una venta. No se cargan las líneas: una línea de un
     *        producto inexistente hacía fallar todo el listado.
     */
    public static MovimientoResponseDTO fromEntity(MovFinanciero mov, BigDecimal costoVenta) {
        BigDecimal costo = BigDecimal.ZERO;
        BigDecimal ganancia = mov.getMonto();

        if (mov.getPago() != null && mov.getPago().getVenta() != null) {
            costo = costoVenta != null ? costoVenta : BigDecimal.ZERO;
            ganancia = mov.getMonto().subtract(costo);
        } else if (mov.getTipo() == TipoMovimiento.EGRESO) {
            costo = mov.getMonto();
            ganancia = mov.getMonto().negate();
        }

        return new MovimientoResponseDTO(
                mov.getId(),
                mov.getTipo().name(),
                mov.getMonto(),
                mov.getMetodoPago(),
                mov.getCategoria(),
                mov.getDescripcion(),
                mov.getFechaHora(),
                costo,
                ganancia
        );
    }
}
