package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record RecetaDetalleRequestDTO(
    @NotNull(message = "El ID de la materia prima es obligatorio")
    Long materiaPrimaId,

    @NotNull(message = "La cantidad es obligatoria")
    @DecimalMin(value = "0.001", message = "La cantidad consumida debe ser mayor a cero")
    BigDecimal cantidad,

    String unidadMedida
) {}
