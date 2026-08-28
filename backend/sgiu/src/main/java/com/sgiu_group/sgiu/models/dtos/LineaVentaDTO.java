package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.Positive;

public record LineaVentaDTO(
    String codigoProducto,
    @Positive(message = "La cantidad debe ser mayor a cero")
    Integer cantidad
) {}