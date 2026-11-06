package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AnulacionVentaRequestDTO(
    @NotBlank(message = "El motivo de anulación es obligatorio")
    @Size(max = 255, message = "El motivo no puede superar los 255 caracteres")
    String motivo
) {}
