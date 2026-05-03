package com.sgiu_group.sgiu.models.dtos;

import java.util.List;

public record VentaRequestDTO(
    Long metodoPago,
    List<LineaVentaDTO> lineas
) {}