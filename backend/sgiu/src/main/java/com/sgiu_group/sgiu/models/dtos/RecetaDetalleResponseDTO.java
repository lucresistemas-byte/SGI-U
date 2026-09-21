package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

public record RecetaDetalleResponseDTO(
    Long id,
    Long materiaPrimaId,
    String materiaPrimaCodigo,
    String materiaPrimaNombre,
    BigDecimal cantidad,
    String unidadMedida,
    BigDecimal costoUnitario,
    BigDecimal subtotal
) {}
