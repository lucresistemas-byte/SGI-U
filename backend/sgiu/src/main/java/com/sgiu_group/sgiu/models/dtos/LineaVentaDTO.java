package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

public record LineaVentaDTO(
    String codigoProducto,
    @Positive(message = "La cantidad debe ser mayor a cero")
    Integer cantidad,
    /**
     * Precio con que el producto entró al carrito (congelado). Si después
     * cambió por una propagación, se respeta el del carrito. Opcional: sin
     * precio se cobra el actual.
     */
    BigDecimal precioUnitario
) {
    public LineaVentaDTO(String codigoProducto, Integer cantidad) {
        this(codigoProducto, cantidad, null);
    }
}
