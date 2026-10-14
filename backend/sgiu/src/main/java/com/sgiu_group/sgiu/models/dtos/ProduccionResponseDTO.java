package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

/** Producción aplicada: lo que entró, lo que se consumió y lo que faltó (si se confirmó igual). */
public record ProduccionResponseDTO(
    Long id,
    String codigo,
    String nombre,
    BigDecimal cantidad,
    BigDecimal costoUnitario,
    boolean conFaltantes,
    List<FaltanteDTO> faltantes,
    List<Consumo> consumos,
    /** Stock del producto después de producir (en unidades). */
    Long stockActual
) {
    public record Consumo(
        String codigo,
        String nombre,
        /** En unidad base, negativo. */
        BigDecimal cantidad,
        String cantidadTexto,
        BigDecimal stockResultante,
        String stockResultanteTexto,
        boolean negativo
    ) {}
}
