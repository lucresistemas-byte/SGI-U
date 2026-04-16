package com.sgiu_group.sgiu.models.dtos;

import java.util.List;

public record VentaRequestDTO(
    String metodoPago,
    List<LineaVentaDTO> lineas
) {}