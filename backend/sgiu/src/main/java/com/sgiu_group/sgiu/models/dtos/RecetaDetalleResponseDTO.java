package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

public record RecetaDetalleResponseDTO(
    Long id,
    Long articuloId,
    String articuloCodigo,
    String articuloNombre,
    String articuloTipo,
    /** En la unidad elegida. */
    BigDecimal cantidad,
    String unidadMedida,
    /** Costo por la unidad elegida. */
    BigDecimal costoUnitario,
    BigDecimal subtotal,
    BigDecimal cantidadBase,
    String unidadBase,
    String familia
) {}
