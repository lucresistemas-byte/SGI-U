package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.math.BigDecimal;
import java.util.List;

public record RecetaRequestDTO(
    @NotBlank(message = "El código del producto elaborado es obligatorio")
    String espProductoCodigo,

    @NotBlank(message = "El nombre de la receta es obligatorio")
    String nombre,

    String descripcion,

    BigDecimal costosAdicionales,

    @NotEmpty(message = "La receta debe contener al menos un insumo")
    @Valid
    List<RecetaDetalleRequestDTO> detalles
) {}
