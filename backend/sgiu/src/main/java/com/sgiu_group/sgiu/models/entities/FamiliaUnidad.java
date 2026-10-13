package com.sgiu_group.sgiu.models.entities;

/**
 * Familia de unidades: solo se convierte dentro de una familia. Cada una tiene
 * una unidad base (la más chica), en la que se guardan el stock y el costo de
 * las materias primas.
 */
public enum FamiliaUnidad {
    PESO("peso"),
    VOLUMEN("volumen"),
    LONGITUD("longitud"),
    UNIDAD("unidades");

    private final String descripcion;

    FamiliaUnidad(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getDescripcion() {
        return descripcion;
    }

    /** Gramo, mililitro, centímetro o unidad. */
    public UnidadMedida getUnidadBase() {
        return switch (this) {
            case PESO -> UnidadMedida.GRAMO;
            case VOLUMEN -> UnidadMedida.MILILITRO;
            case LONGITUD -> UnidadMedida.CENTIMETRO;
            case UNIDAD -> UnidadMedida.UNIDAD;
        };
    }
}
