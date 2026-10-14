package com.sgiu_group.sgiu.models.dtos;

import com.sgiu_group.sgiu.models.entities.TipoArticulo;
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
    Boolean activo,
    TipoArticulo tipo,
    /** false = preparación base (no se vende en el POS). */
    Boolean vendible,
    /**
     * Reventa + materia prima: unidad en que se vende ("Caja"). El stock y el
     * stock mínimo vienen en esa unidad (cajas enteras).
     */
    String unidadVenta,
    /** true = el precio se fijó a mano y no sigue al costo. */
    Boolean precioManual
) {
    /** Producto de reventa vendible (compatibilidad de tests y fixtures). */
    public ProductoCatalogoDTO(
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
        this(codigo, nombre, precioUnitario, precioCosto, porcentajeGanancia, unidadMedida,
                categoria, stockActual, stockMinimo, activo, TipoArticulo.REVENTA, true, null, false);
    }

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