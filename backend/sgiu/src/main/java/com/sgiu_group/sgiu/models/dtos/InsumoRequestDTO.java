package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record InsumoRequestDTO(
    /**
     * Solo al crear: MATERIA_PRIMA (por defecto), INSUMO o REVENTA_MATERIA_PRIMA.
     * El código lo genera el sistema según el tipo (MP-, INS-, RMP-).
     */
    String tipo,

    @NotBlank(message = "El nombre de insumo es obligatorio")
    String nombre,

    @NotNull(message = "El costo unitario es obligatorio")
    @DecimalMin(value = "0.0", inclusive = true, message = "El costo unitario no puede ser negativo")
    BigDecimal costoUnitario,

    String unidadMedida,

    Integer stockActual,

    Integer stockMinimo
) {}
