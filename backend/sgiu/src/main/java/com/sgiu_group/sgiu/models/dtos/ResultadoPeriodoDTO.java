package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

/**
 * Resultado de un período, en pesos (glosario de docs/ANALISIS_FINANZAS.md):
 * <ul>
 *   <li>ventas: lo cobrado por las ventas del POS.</li>
 *   <li>costoVendido: costo congelado de lo vendido (lineas_venta).</li>
 *   <li>gananciaBruta = ventas − costoVendido.</li>
 *   <li>otrosIngresos: ingresos cargados a mano (sin venta).</li>
 *   <li>gastos: egresos salvo la compra de mercadería.</li>
 *   <li>comprasMercaderia: egresos COMPRA. No se restan de la ganancia: su
 *       costo ya entra en costoVendido cuando se vende; solo cuentan en la
 *       caja.</li>
 *   <li>gananciaNeta = gananciaBruta + otrosIngresos − gastos.</li>
 * </ul>
 * Los márgenes son sobre las ventas, en %, y null si no hubo ventas.
 */
public record ResultadoPeriodoDTO(
    BigDecimal ventas,
    BigDecimal costoVendido,
    BigDecimal gananciaBruta,
    BigDecimal margenBrutoPorcentaje,
    BigDecimal otrosIngresos,
    BigDecimal gastos,
    BigDecimal comprasMercaderia,
    BigDecimal gananciaNeta,
    BigDecimal margenNetoPorcentaje
) {}
