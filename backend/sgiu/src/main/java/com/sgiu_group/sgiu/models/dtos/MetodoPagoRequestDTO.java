package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MetodoPagoRequestDTO(
    @NotBlank(message = "El nombre del método de pago es obligatorio.")
    @Size(max = 50, message = "El nombre del método de pago admite hasta 50 caracteres.")
    String nombre
) {}
