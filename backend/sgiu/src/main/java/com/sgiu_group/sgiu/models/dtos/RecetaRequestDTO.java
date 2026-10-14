package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import java.math.BigDecimal;
import java.util.List;

public record RecetaRequestDTO(
    /** Producto elaborado existente. Al crear, este o productoNuevo (uno de los dos). */
    String espProductoCodigo,
    /** Producto elaborado que se crea junto con la receta. */
    @Valid
    ProductoElaboradoNuevoDTO productoNuevo,

    @NotBlank(message = "El nombre de la receta es obligatorio")
    String nombre,

    String descripcion,

    BigDecimal costosAdicionales,

    @NotNull(message = "Indique el rinde de la receta")
    @DecimalMin(value = "0.001", message = "El rinde de la receta debe ser mayor a cero")
    BigDecimal rinde,

    /** Qué rinde ("porciones", "unidades"); por defecto, unidades. */
    String rindeUnidad,

    @NotEmpty(message = "La receta debe contener al menos un insumo")
    @Valid
    List<RecetaDetalleRequestDTO> detalles
) {}
