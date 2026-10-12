package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/** Todos los métodos de pago, en el orden en que se ofrecen. */
public record OrdenMetodosPagoDTO(
    @NotEmpty(message = "Indique el orden de los métodos de pago.")
    List<Long> ids
) {}
