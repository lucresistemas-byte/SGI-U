package com.sgiu_group.sgiu.models.dtos;

import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;

public record ProductoRequestDTO(
    String codigo,
    String nombre,
    @DecimalMin(value = "0.01", message = "El precio debe ser un valor mayor a $0.")
    BigDecimal precioUnitario,
    BigDecimal precioCosto,
    BigDecimal porcentajeGanancia,
    String unidadMedida,
    Long categoriaId,
    @Min(value = 0, message = "El stock no puede ser negativo.")
    Long stockActual,
    @Min(value = 0, message = "El stock mínimo no puede ser negativo.")
    Integer stockMinimo,
    Boolean activo,
    /** Obligatorio al crear (ver TipoArticulo); no se puede cambiar al editar. */
    String tipo,
    /** false = preparación base (solo ELABORADO). */
    Boolean vendible
) {
    public ProductoRequestDTO(
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
            "UNIDAD",
            null,
            stockActual,
            stockMinimo,
            activo,
            "REVENTA",
            null
        );
    }

    public ProductoRequestDTO(
            String codigo,
            String nombre,
            BigDecimal precioUnitario,
            BigDecimal precioCosto,
            BigDecimal porcentajeGanancia,
            UnidadMedida unidadMedida,
            Long categoriaId,
            Long stockActual,
            Integer stockMinimo,
            Boolean activo
    ) {
        this(
            codigo,
            nombre,
            precioUnitario,
            precioCosto,
            porcentajeGanancia,
            unidadMedida != null ? unidadMedida.name() : "UNIDAD",
            categoriaId,
            stockActual,
            stockMinimo,
            activo,
            "REVENTA",
            null
        );
    }
}