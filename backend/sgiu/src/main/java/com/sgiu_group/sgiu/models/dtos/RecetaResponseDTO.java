package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

public record RecetaResponseDTO(
    Long id,
    String espProductoCodigo,
    String espProductoNombre,
    String nombre,
    String descripcion,
    BigDecimal costosAdicionales,
    BigDecimal costoTotal,
    List<RecetaDetalleResponseDTO> detalles,
    boolean activo,
    /** false = el producto elaborado está desactivado (no se vende en el POS). */
    boolean productoActivo,
    BigDecimal rinde,
    String rindeUnidad,
    /** Costo de una unidad rendida = costoTotal / rinde (costo del elaborado). */
    BigDecimal costoPorUnidad,
    BigDecimal porcentajeGanancia,
    /** Precio del elaborado según su modo, redondeado hacia arriba a $100. */
    BigDecimal precioVenta,
    /** precioVenta − costoPorUnidad. */
    BigDecimal gananciaPorUnidad,
    String modoPrecio,
    /** true = preparación base (no se vende; rinde en peso o volumen). */
    boolean preparacionBase,
    String rindeUnidadMedida,
    /** Preparación base: costo por unidad base del rinde (4 decimales). */
    BigDecimal costoUnidadBase,
    /** Precios que cambiaron al guardar (resumen "Se actualizaron N precios"). */
    List<CambioPrecioDTO> cambiosDePrecio
) {}
