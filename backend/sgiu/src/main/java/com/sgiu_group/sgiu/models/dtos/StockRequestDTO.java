package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotNull;

public record StockRequestDTO(
    @NotNull(message = "La cantidad es obligatoria.")
    Integer cantidad
) {}
