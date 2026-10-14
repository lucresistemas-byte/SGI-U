package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Alta/edición de un artículo de Materia Prima (materia prima, insumo o
 * reventa + materia prima). El costo sale de la presentación de compra (p. ej.
 * "Bolsa 25 kg": 25 KILO a $30.000). Las cantidades de stock se escriben en
 * {@code stockUnidad} y se guardan en unidad base.
 */
public record MateriaPrimaRequestDTO(
    /**
     * Solo al crear: MATERIA_PRIMA (por defecto), INSUMO o REVENTA_MATERIA_PRIMA.
     * El código lo genera el sistema según el tipo (MP-, INS-, RMP-).
     */
    String tipo,

    @NotBlank(message = "El nombre es obligatorio")
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

    /**
     * Unidad de stockActual y stockMinimo: una de la familia, PRESENTACION o
     * UNIDAD_VENTA (por defecto, unidadMedida).
     */
    String stockUnidad,

    // --- Solo reventa + materia prima ---

    /** Cómo se vende ("Caja"). Por defecto, la descripción de la presentación. */
    String ventaUnidadNombre,

    /** Contenido de la unidad de venta. Sin contenido, se vende la presentación de compra. */
    @DecimalMin(value = "0.001", message = "El contenido de la unidad de venta debe ser mayor a cero")
    BigDecimal ventaUnidadCantidad,

    /** Unidad del contenido (de la familia). */
    String ventaUnidadUnidad,

    @DecimalMin(value = "0.0", message = "El porcentaje de ganancia no puede ser negativo")
    BigDecimal porcentajeGanancia,

    /** Precio fijado a mano. Vacío = costo de la unidad de venta × (1 + % de ganancia). */
    @DecimalMin(value = "0.01", message = "El precio de venta debe ser mayor a $0.")
    BigDecimal precioVenta,

    Long categoriaId
) {}
