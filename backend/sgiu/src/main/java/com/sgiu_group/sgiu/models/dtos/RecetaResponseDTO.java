package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

public record RecetaResponseDTO(
    Long id,
    String espProductoCodigo,
    String espProductoNombre,
    String nombre,
    String descripcion,
    BigDecimal costosAdicionales,
    BigDecimal costoTotal,
    List<RecetaDetalleResponseDTO> detalles,
    boolean activo
) {}
