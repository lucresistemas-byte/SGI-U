package com.sgiu_group.sgiu.models.dtos;

import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import java.math.BigDecimal;

public record ProductoCatalogoDTO(
    String codigo,
    String nombre,
    BigDecimal precioUnitario,
    BigDecimal precioCosto,
    BigDecimal porcentajeGanancia,
    UnidadMedida unidadMedida,
    String categoria,
    Long stockActual,
    Integer stockMinimo,
    Boolean activo
) {
    public ProductoCatalogoDTO(
            String codigo,
            String nombre,
            BigDecimal precioUnitario,
            Long stockActual,
            Integer stockMinimo,
            Boolean activo
    ) {
        this(
            codigo,
            nombre,
            precioUnitario,
            BigDecimal.ZERO,
            BigDecimal.ZERO,
            UnidadMedida.UNIDAD,
            null,
            stockActual,
            stockMinimo,
            activo
        );
    }
}