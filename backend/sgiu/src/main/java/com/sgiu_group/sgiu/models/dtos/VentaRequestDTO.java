package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record VentaRequestDTO(
    Long metodoPago,
    @Valid @NotEmpty(message = "La venta debe tener al menos una línea.")
    List<LineaVentaDTO> lineas
) {
    public VentaRequestDTO(List<LineaVentaDTO> lineas, String metodoPago) {
        this(1L, lineas);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, Long metodoPago) {
        this(metodoPago, lineas);
    }
}