package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record MovimientoRequestDTO(
    @NotBlank(message = "El tipo es obligatorio.")
    String tipo,
    @NotNull(message = "El monto es obligatorio.")
    @Positive(message = "El monto debe ser mayor a cero.")
    BigDecimal monto,
    @NotBlank(message = "El método de pago es obligatorio.")
    String metodoPago,
    String categoria,
    String descripcion,
    @NotNull(message = "La fecha y hora es obligatoria.")
    LocalDateTime fechaHora
) {}
