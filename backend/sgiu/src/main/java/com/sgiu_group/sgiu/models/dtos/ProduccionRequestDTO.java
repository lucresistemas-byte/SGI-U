package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/** Producir (cargar stock de) un elaborado o un paquete. */
public record ProduccionRequestDTO(
    @NotNull(message = "Indique cuánto se produjo")
    @Positive(message = "La cantidad a producir debe ser mayor a cero")
    Integer cantidad,

    /** true = producir aunque falten componentes (el stock queda negativo). */
    Boolean confirmarFaltantes,

    String motivo
) {}
