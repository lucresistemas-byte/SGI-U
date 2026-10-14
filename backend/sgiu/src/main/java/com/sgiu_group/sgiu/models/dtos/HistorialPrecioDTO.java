package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record HistorialPrecioDTO(
    Long id,
    LocalDateTime fecha,
    String codigo,
    String nombre,
    String tipo,
    BigDecimal costoAnterior,
    BigDecimal costoNuevo,
    BigDecimal precioAnterior,
    BigDecimal precioNuevo,
    String modoPrecio,
    String causa,
    String usuario
) {}
