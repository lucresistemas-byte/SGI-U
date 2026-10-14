package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

/** Un precio de venta que cambió por una propagación (para el resumen "Se actualizaron N precios"). */
public record CambioPrecioDTO(
    String codigo,
    String nombre,
    BigDecimal precioAnterior,
    BigDecimal precioNuevo,
    BigDecimal costoNuevo,
    /** Precio nuevo − costo unitario nuevo. */
    BigDecimal gananciaPesos
) {}
