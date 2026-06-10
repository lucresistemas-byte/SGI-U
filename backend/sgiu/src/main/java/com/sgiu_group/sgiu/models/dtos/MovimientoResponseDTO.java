package com.sgiu_group.sgiu.models.dtos;

import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record MovimientoResponseDTO(
    Long id,
    String tipo,
    BigDecimal monto,
    String metodoPago,
    String categoria,
    String descripcion,
    LocalDateTime fechaHora
) {
    public static MovimientoResponseDTO fromEntity(MovFinanciero mov) {
        return new MovimientoResponseDTO(
                mov.getId(),
                mov.getTipo().name(),
                mov.getMonto(),
                mov.getMetodoPago(),
                mov.getCategoria(),
                mov.getDescripcion(),
                mov.getFechaHora()
        );
    }
}
