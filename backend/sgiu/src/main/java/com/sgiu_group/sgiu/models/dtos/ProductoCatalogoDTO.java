package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

public record ProductoCatalogoDTO(
    String codigo,
    String nombre,
    BigDecimal precioUnitario,
    Long stockActual,
    Boolean activo
) {}