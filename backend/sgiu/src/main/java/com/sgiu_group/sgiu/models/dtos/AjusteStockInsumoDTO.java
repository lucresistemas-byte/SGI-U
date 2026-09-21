package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record AjusteStockInsumoDTO(
    @NotNull(message = "La cantidad es obligatoria")
    Integer cantidad,

    @NotBlank(message = "El motivo del ajuste es obligatorio")
    String motivo
) {}
