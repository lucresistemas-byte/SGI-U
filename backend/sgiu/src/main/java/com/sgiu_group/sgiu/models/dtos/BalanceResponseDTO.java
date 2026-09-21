package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

public record BalanceResponseDTO(
    BigDecimal totalIngresos,
    BigDecimal totalEgresos,
    BigDecimal margenNeto,
    BigDecimal costoTotal,
    BigDecimal gananciaReal,
    List<MovimientoResponseDTO> movimientos
) {
    public BalanceResponseDTO(
            BigDecimal totalIngresos,
            BigDecimal totalEgresos,
            BigDecimal margenNeto,
            List<MovimientoResponseDTO> movimientos
    ) {
        this(totalIngresos, totalEgresos, margenNeto, BigDecimal.ZERO, margenNeto, movimientos);
    }
}
