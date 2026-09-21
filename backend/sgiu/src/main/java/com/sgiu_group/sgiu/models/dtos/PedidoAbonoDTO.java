package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record PedidoAbonoDTO(
    Long id,
    BigDecimal monto,
    String metodoPago,
    String nota,
    LocalDateTime fecha
) {}
