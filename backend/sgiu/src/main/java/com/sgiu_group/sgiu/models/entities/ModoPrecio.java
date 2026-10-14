package com.sgiu_group.sgiu.models.entities;

/** Cómo se calcula el precio de venta de un artículo (ver CostosService). */
public enum ModoPrecio {
    /** Precio = costo unitario × (1 + % de ganancia), redondeado hacia arriba a $100. */
    MARGEN,
    /**
     * Precio fijado por Sandra. Se conserva mientras deje al menos el % de
     * ganancia del producto; si un aumento de costo lo deja por debajo, sube
     * solo al mínimo.
     */
    MANUAL,
    /** Paquetes: costo del armado + monto fijo, redondeado hacia arriba a $100. */
    COSTO_MAS_FIJO
}
