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

    public static MovimientoResponseDTO fromEntity(MovFinanciero mov) {
        BigDecimal costo = BigDecimal.ZERO;
        BigDecimal ganancia = mov.getMonto();

        if (mov.getPago() != null && mov.getPago().getVenta() != null) {
            var venta = mov.getPago().getVenta();
            if (venta.getLineas() != null && !venta.getLineas().isEmpty()) {
                costo = venta.getLineas().stream()
                        .map(l -> (l.getCostoUnitario() != null ? l.getCostoUnitario() : BigDecimal.ZERO)
                                .multiply(BigDecimal.valueOf(l.getCantidad())))
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
            }
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
