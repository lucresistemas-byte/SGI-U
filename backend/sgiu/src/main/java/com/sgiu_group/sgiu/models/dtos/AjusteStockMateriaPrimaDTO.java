package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Ajuste de stock (positivo suma, negativo resta). La unidad puede ser una de
 * la familia, PRESENTACION ("llegó 1 bulto") o UNIDAD_VENTA ("3 cajas").
 */
public record AjusteStockMateriaPrimaDTO(
    @NotNull(message = "La cantidad es obligatoria")
    BigDecimal cantidad,

    /** Por defecto, la unidad para mostrar. */
    String unidad,

    @NotBlank(message = "El motivo del ajuste es obligatorio")
    String motivo,

    /** COMPRA (suma), AJUSTE o MERMA (resta). Por defecto: COMPRA si suma y AJUSTE si resta. */
    String tipo
) {
    public AjusteStockMateriaPrimaDTO(BigDecimal cantidad, String unidad, String motivo) {
        this(cantidad, unidad, motivo, null);
    }
}
