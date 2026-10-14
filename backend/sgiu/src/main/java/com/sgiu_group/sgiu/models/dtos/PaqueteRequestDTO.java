package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;

/** Alta/edición de un paquete: nombre, categoría, armado (insumos) y monto fijo. */
public record PaqueteRequestDTO(
    @NotBlank(message = "El nombre del paquete es obligatorio")
    String nombre,

    Long categoriaId,

    @NotNull(message = "Indique el monto fijo del paquete (puede ser 0)")
    @DecimalMin(value = "0.0", message = "El monto fijo no puede ser negativo")
    BigDecimal montoFijo,

    @NotEmpty(message = "El armado del paquete debe tener al menos un insumo")
    @Valid
    List<Fila> armado
) {
    public record Fila(
        @NotNull(message = "Indique el insumo de cada fila del armado")
        Long articuloId,

        @NotNull(message = "La cantidad es obligatoria")
        @DecimalMin(value = "0.001", message = "La cantidad debe ser mayor a cero")
        BigDecimal cantidad,

        /** De la familia del insumo; sin unidad, la base. */
        String unidadMedida
    ) {}
}
