package com.sgiu_group.sgiu.models.entities;

/**
 * Tipo de artículo del catálogo. Todo comportamiento (qué se vende en el POS,
 * qué tiene receta) depende del tipo, nunca de la categoría: las categorías
 * son etiquetas de Sandra para filtrar y para los reportes.
 * Ver docs/MODELO_PRODUCTOS.md.
 */
public enum TipoArticulo {
    /** Tiene receta; se vende en el POS, salvo que sea una preparación base. */
    ELABORADO,
    /** Se compra y se vende tal cual. No se usa en recetas. */
    REVENTA,
    /** Solo se usa en recetas (etapa 3). */
    MATERIA_PRIMA,
    /** Cajas, cintas, stickers: recetas y armados de paquetes (etapa 3). */
    INSUMO,
    /** Se vende tal cual y también se usa en recetas (etapa 3). */
    REVENTA_MATERIA_PRIMA,
    /** Paquete armado con insumos, una línea en el ticket (etapa 4). */
    PAQUETE;

    /** Si los artículos de este tipo pueden venderse en el POS. */
    public boolean seVende() {
        return this == ELABORADO || this == REVENTA || this == REVENTA_MATERIA_PRIMA || this == PAQUETE;
    }

    /** Si los artículos de este tipo tienen receta de producción. */
    public boolean tieneReceta() {
        return this == ELABORADO;
    }
}
