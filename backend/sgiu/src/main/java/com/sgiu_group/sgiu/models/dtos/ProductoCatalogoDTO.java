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
    /** MARGEN, MANUAL o COSTO_MAS_FIJO (paquetes). */
    String modoPrecio,
    /** Ganancia por unidad en pesos: precio − costo unitario (null en preparaciones base). */
    BigDecimal gananciaPesos,
    /** Paquetes: monto fijo que se suma al costo del armado. */
    BigDecimal montoFijo,
    /** Precios que cambiaron al guardar (resumen "Se actualizaron N precios"). */
    java.util.List<CambioPrecioDTO> cambiosDePrecio,
    /** Elaborados y paquetes: cuántos se pueden producir con el stock de sus componentes. */
    Long puedeProducir,
    /** Id interno (el filtro por producto del dashboard lo usa). */
    Long id
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
                categoria, stockActual, stockMinimo, activo, TipoArticulo.REVENTA, true, null, "MARGEN", null, null,
                java.util.List.of(), null, null);
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