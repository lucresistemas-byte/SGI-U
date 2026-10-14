package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record StockRequestDTO(
    @NotNull(message = "La cantidad es obligatoria.")
    Integer cantidad,
    
    @NotBlank(message = "El motivo es obligatorio.")
    String motivo,

    /**
     * COMPRA (suma), AJUSTE o MERMA (resta). Por defecto: COMPRA si suma y
     * AJUSTE si resta. Un elaborado o un paquete suma produciendo.
     */
    String tipo
) {
    public StockRequestDTO(Integer cantidad, String motivo) {
        this(cantidad, motivo, null);
    }
}
