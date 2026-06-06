package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;

public record ProductoRequestDTO(
    String codigo,
    String nombre,
    @DecimalMin(value = "0.01", message = "El precio debe ser un valor mayor a $0.")
    BigDecimal precioUnitario,
    @Min(value = 0, message = "El stock no puede ser negativo.")
    Long stockActual,
    Boolean activo
) {}