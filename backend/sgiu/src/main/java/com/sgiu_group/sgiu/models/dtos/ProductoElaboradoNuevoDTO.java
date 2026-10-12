package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;

/**
 * Datos del producto elaborado que se crea junto con su receta (la receta
 * crea el elaborado). El código lo genera el sistema (ELA-0001).
 */
public record ProductoElaboradoNuevoDTO(
    @NotBlank(message = "El nombre del producto elaborado es obligatorio")
    String nombre,
    Long categoriaId,
    @DecimalMin(value = "0.0", message = "El porcentaje de ganancia no puede ser negativo")
    BigDecimal porcentajeGanancia,
    /** false = preparación base (no se vende). Por defecto, true. */
    Boolean vendible
) {}
