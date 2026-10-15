package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Una fila del historial de stock de un artículo. */
public record MovimientoStockDTO(
    Long id,
    LocalDateTime fecha,
    String codigo,
    String nombre,
    String tipo,
    String tipoDescripcion,
    /** En unidad base, con signo. */
    BigDecimal cantidad,
    String cantidadTexto,
    BigDecimal stockResultante,
    String stockResultanteTexto,
    String motivo,
    Long produccionId,
    Long ventaId,
    String usuario
) {}
