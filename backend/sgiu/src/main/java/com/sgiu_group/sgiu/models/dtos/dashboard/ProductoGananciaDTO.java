package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;

/**
 * Lo que dejó un producto en el período: unidades, lo vendido, el costo
 * congelado de esas ventas y la ganancia (ventas − costo), en pesos.
 */
public record ProductoGananciaDTO(
    Long productoId,
    String nombre,
    Long cantidadVendida,
    BigDecimal ventas,
    BigDecimal costo,
    BigDecimal ganancia
) {}
