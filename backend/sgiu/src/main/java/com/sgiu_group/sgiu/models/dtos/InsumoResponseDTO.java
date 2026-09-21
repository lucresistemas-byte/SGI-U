package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

public record InsumoResponseDTO(
    Long id,
    String codigo,
    String nombre,
    BigDecimal costoUnitario,
    String unidadMedida,
    Integer stockActual,
    Integer stockMinimo,
    boolean activo
) {}
