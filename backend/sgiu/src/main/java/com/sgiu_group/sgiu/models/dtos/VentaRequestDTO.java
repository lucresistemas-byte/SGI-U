package com.sgiu_group.sgiu.models.dtos;

import java.util.List;

public record VentaRequestDTO(
    Long metodoPago,
    List<LineaVentaDTO> lineas
) {
    public VentaRequestDTO(List<LineaVentaDTO> lineas, String metodoPago) {
        this(1L, lineas);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, Long metodoPago) {
        this(metodoPago, lineas);
    }
}