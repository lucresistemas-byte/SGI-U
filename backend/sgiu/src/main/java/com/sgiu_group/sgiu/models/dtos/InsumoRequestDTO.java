package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Alta/edición de materia prima. El costo sale de la presentación de compra
 * (p. ej. "Bolsa 25 kg": 25 KILO a $30.000). Las cantidades de stock se
 * escriben en {@code stockUnidad} (cualquier unidad de la familia; por
 * defecto, la unidad para mostrar) y se guardan en unidad base.
 */
public record InsumoRequestDTO(
    /**
     * Solo al crear: MATERIA_PRIMA (por defecto), INSUMO o REVENTA_MATERIA_PRIMA.
     * El código lo genera el sistema según el tipo (MP-, INS-, RMP-).
     */
    String tipo,

    @NotBlank(message = "El nombre de insumo es obligatorio")
    String nombre,

    /** Unidad para mostrar; define la familia (peso, volumen, longitud o unidades). */
    @NotBlank(message = "La unidad de medida es obligatoria")
    String unidadMedida,

    String presentacionDescripcion,

    @NotNull(message = "Indique cuánto trae la presentación de compra")
    @DecimalMin(value = "0.001", message = "La cantidad de la presentación debe ser mayor a cero")
    BigDecimal presentacionCantidad,

    @NotBlank(message = "Indique la unidad de la presentación de compra")
    String presentacionUnidad,

    @NotNull(message = "Indique el precio de la presentación de compra")
    @DecimalMin(value = "0.0", message = "El precio no puede ser negativo")
    BigDecimal presentacionPrecio,

    /** Solo al crear. */
    @DecimalMin(value = "0.0", message = "El stock no puede ser negativo")
    BigDecimal stockActual,

    @DecimalMin(value = "0.0", message = "El stock mínimo no puede ser negativo")
    BigDecimal stockMinimo,

    /** Unidad de stockActual y stockMinimo (por defecto, unidadMedida). */
    String stockUnidad
) {}
