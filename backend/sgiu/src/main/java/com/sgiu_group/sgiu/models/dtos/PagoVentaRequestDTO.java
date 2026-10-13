package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

/**
 * Una línea de pago de la venta. En efectivo, el monto es lo que entrega el
 * cliente (puede superar lo que falta: la diferencia es el vuelto).
 */
public record PagoVentaRequestDTO(
    @NotNull(message = "Indique el método de cada pago.")
    Long metodoPagoId,
    @NotNull(message = "Indique el monto de cada pago.")
    @Positive(message = "El monto de cada pago debe ser mayor a cero.")
    BigDecimal monto
) {}
