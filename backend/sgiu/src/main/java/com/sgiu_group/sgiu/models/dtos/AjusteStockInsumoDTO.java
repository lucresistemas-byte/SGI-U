package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/** Ajuste de stock (positivo suma, negativo resta) en cualquier unidad de la familia. */
public record AjusteStockInsumoDTO(
    @NotNull(message = "La cantidad es obligatoria")
    BigDecimal cantidad,

    /** Por defecto, la unidad para mostrar del insumo. */
    String unidad,

    @NotBlank(message = "El motivo del ajuste es obligatorio")
    String motivo
) {}
