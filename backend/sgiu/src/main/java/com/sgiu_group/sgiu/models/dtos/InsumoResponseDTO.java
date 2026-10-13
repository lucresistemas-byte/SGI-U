package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

/** Stock y costo en unidad base; costoUnitario es por la unidad para mostrar. */
public record InsumoResponseDTO(
    Long id,
    String codigo,
    String tipo,
    String nombre,
    String familia,
    String unidadMedida,
    String unidadBase,
    BigDecimal costoUnidadBase,
    BigDecimal costoUnitario,
    String presentacionDescripcion,
    BigDecimal presentacionCantidad,
    String presentacionUnidad,
    BigDecimal presentacionPrecio,
    BigDecimal stockActual,
    BigDecimal stockMinimo,
    boolean activo
) {}
