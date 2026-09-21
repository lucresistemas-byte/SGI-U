package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record AbonoRequestDTO(
    @NotNull(message = "El monto a abonar es obligatorio")
    @DecimalMin(value = "0.01", message = "El monto a abonar debe ser mayor a cero")
    BigDecimal monto,

    String metodoPago,

    String nota
) {}
