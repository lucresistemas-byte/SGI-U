package com.sgiu_group.sgiu.models.entities;

/** Por qué cambió el stock de un artículo (historial de stock). */
public enum TipoMovimientoStock {
    /** Entra mercadería comprada. */
    COMPRA("Compra"),
    /** Corrección manual (recuento, carga inicial...). */
    AJUSTE("Ajuste"),
    /** Se tiró o se rompió: siempre resta. */
    MERMA("Merma"),
    /** Entra lo producido (elaborado o paquete). */
    PRODUCCION("Producción"),
    /** Sale lo que consumió una producción (ingredientes, insumos). */
    CONSUMO_PRODUCCION("Consumo de producción"),
    /** Sale lo vendido en el POS. */
    VENTA("Venta");

    private final String descripcion;

    TipoMovimientoStock(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getDescripcion() {
        return descripcion;
    }
}
