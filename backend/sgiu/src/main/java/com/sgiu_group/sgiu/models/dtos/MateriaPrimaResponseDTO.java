package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

/**
 * Stock y costo en unidad base; costoUnitario es por la unidad para mostrar.
 * Los campos de venta solo vienen en la reventa + materia prima.
 */
public record MateriaPrimaResponseDTO(
    Long id,
    String codigo,
    String tipo,
    String nombre,
    String familia,
    String unidadMedida,
    String unidadBase,
    BigDecimal costoUnidadBase,
    BigDecimal costoUnitario,
    String presentacionDescripcion,
    BigDecimal presentacionCantidad,
    String presentacionUnidad,
    BigDecimal presentacionPrecio,
    BigDecimal stockActual,
    BigDecimal stockMinimo,
    boolean activo,
    String ventaUnidadNombre,
    /** En unidad base. */
    BigDecimal ventaUnidadContenido,
    /** Unidades de venta enteras en stock (lo que ofrece el POS). */
    Long stockUnidadesVenta,
    /** Lo que queda suelto, en unidad base (p. ej. 50 g). */
    BigDecimal stockSuelto,
    BigDecimal costoUnidadVenta,
    BigDecimal porcentajeGanancia,
    BigDecimal precioVenta,
    boolean precioManual,
    Long categoriaId
) {}
