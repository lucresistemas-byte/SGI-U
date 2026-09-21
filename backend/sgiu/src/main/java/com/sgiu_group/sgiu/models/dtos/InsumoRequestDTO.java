package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record InsumoRequestDTO(
    @NotBlank(message = "El código de insumo es obligatorio")
    String codigo,

    @NotBlank(message = "El nombre de insumo es obligatorio")
    String nombre,

    @NotNull(message = "El costo unitario es obligatorio")
    @DecimalMin(value = "0.0", inclusive = true, message = "El costo unitario no puede ser negativo")
    BigDecimal costoUnitario,

    String unidadMedida,

    Integer stockActual,

    Integer stockMinimo
) {}
