package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;

public record CategoriaMasVendidaDTO(
    Long categoriaId,
    String nombre,
    Long cantidadVendida,
    BigDecimal montoTotal
) {}
