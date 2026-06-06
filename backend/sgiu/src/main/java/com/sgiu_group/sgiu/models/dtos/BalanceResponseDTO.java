package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

public record BalanceResponseDTO(
    BigDecimal totalIngresos,
    BigDecimal totalEgresos,
    BigDecimal margenNeto,
    List<MovimientoResponseDTO> movimientos
) {}
