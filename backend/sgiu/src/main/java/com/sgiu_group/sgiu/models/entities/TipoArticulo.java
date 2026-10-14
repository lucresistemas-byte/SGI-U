package com.sgiu_group.sgiu.models.entities;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;

/**
 * Tipo de artículo del catálogo. Todo comportamiento (qué se vende en el POS,
 * qué tiene receta) depende del tipo, nunca de la categoría: las categorías
 * son etiquetas de Sandra para filtrar y para los reportes.
 * Ver docs/MODELO_PRODUCTOS.md.
 */
public enum TipoArticulo {
    /** Tiene receta; se vende en el POS, salvo que sea una preparación base. */
    ELABORADO("ELA"),
    /** Se compra y se vende tal cual. No se usa en recetas. */
    REVENTA("REV"),
    /** Solo se usa en recetas. */
    MATERIA_PRIMA("MP"),
    /** Cajas, cintas, stickers: recetas y armados de paquetes. */
    INSUMO("INS"),
    /** Se vende por unidades enteras (p. ej. una caja de 100 g) y también se usa en recetas. */
    REVENTA_MATERIA_PRIMA("RMP"),
    /** Paquete armado con insumos, una línea en el ticket (etapa 4). */
    PAQUETE("PAQ");

    private final String prefijo;

    TipoArticulo(String prefijo) {
        this.prefijo = prefijo;
    }

    /** Prefijo del código que genera el sistema (ELA-0001, REV-0001, ...). */
    public String getPrefijo() {
        return prefijo;
    }

    /** Tipos que se cargan en Materia Prima y se pueden usar en recetas. */
    public boolean esDeMateriaPrima() {
        return this == MATERIA_PRIMA || this == INSUMO || this == REVENTA_MATERIA_PRIMA;
    }

    /** Si los artículos de este tipo pueden venderse en el POS. */
    public boolean seVende() {
        return this == ELABORADO || this == REVENTA || this == REVENTA_MATERIA_PRIMA || this == PAQUETE;
    }

    /** Si los artículos de este tipo tienen receta de producción. */
    public boolean tieneReceta() {
        return this == ELABORADO;
    }

    /** Los que se venden en el POS y se listan en Productos. */
    public static Set<TipoArticulo> vendibles() {
        return filtrar(true);
    }

    /** Los que se listan en Materia Prima y se usan en recetas. */
    public static Set<TipoArticulo> deMateriaPrima() {
        return filtrar(false);
    }

    private static Set<TipoArticulo> filtrar(boolean vendibles) {
        EnumSet<TipoArticulo> tipos = EnumSet.noneOf(TipoArticulo.class);
        Arrays.stream(values())
                .filter(t -> vendibles ? t.seVende() : t.esDeMateriaPrima())
                .forEach(tipos::add);
        return tipos;
    }
}
