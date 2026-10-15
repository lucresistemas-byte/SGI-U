package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

/** Un componente que no alcanza para producir: "Faltan 120 g de Coco rallado: hay 380 g, se necesitan 500 g". */
public record FaltanteDTO(
    String codigo,
    String nombre,
    /** En unidad base. */
    BigDecimal hay,
    BigDecimal necesita,
    BigDecimal falta,
    String mensaje
) {}
