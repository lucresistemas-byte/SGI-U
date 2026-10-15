package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

public record BalanceResponseDTO(
    BigDecimal totalIngresos,
    BigDecimal totalEgresos,
    BigDecimal margenNeto,
    BigDecimal costoTotal,
    /** Igual a resultado.gananciaNeta (las compras de mercadería no se restan). */
    BigDecimal gananciaReal,
    List<MovimientoResponseDTO> movimientos,
    ResultadoPeriodoDTO resultado
) {
    public BalanceResponseDTO(
            BigDecimal totalIngresos,
            BigDecimal totalEgresos,
            BigDecimal margenNeto,
            List<MovimientoResponseDTO> movimientos
    ) {
        this(totalIngresos, totalEgresos, margenNeto, BigDecimal.ZERO, margenNeto, movimientos, null);
    }
}
