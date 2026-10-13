package com.sgiu_group.sgiu.models.entities;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Arrays;
import java.util.List;

/**
 * Unidades de medida. Las de materias primas pertenecen a una familia y se
 * convierten a su unidad base: KILO = 1000 g, LITRO = 1000 ml,
 * METRO = 100 cm, DOCENA = 12 unidades.
 * CAJA solo se usa en productos (no tiene familia ni conversión).
 */
public enum UnidadMedida {
    GRAMO(FamiliaUnidad.PESO, 1, "g"),
    KILO(FamiliaUnidad.PESO, 1000, "kg"),
    MILILITRO(FamiliaUnidad.VOLUMEN, 1, "ml"),
    LITRO(FamiliaUnidad.VOLUMEN, 1000, "l"),
    CENTIMETRO(FamiliaUnidad.LONGITUD, 1, "cm"),
    METRO(FamiliaUnidad.LONGITUD, 100, "m"),
    UNIDAD(FamiliaUnidad.UNIDAD, 1, "u"),
    DOCENA(FamiliaUnidad.UNIDAD, 12, "docena"),
    CAJA(null, 1, "caja");

    private final FamiliaUnidad familia;
    private final BigDecimal factor;
    private final String abreviatura;

    UnidadMedida(FamiliaUnidad familia, int factor, String abreviatura) {
        this.familia = familia;
        this.factor = BigDecimal.valueOf(factor);
        this.abreviatura = abreviatura;
    }

    /** null solo para CAJA (unidad de productos, sin conversión). */
    public FamiliaUnidad getFamilia() {
        return familia;
    }

    /** Cuántas unidades base tiene una de esta unidad (1 kg = 1000 g). */
    public BigDecimal getFactor() {
        return factor;
    }

    public String getAbreviatura() {
        return abreviatura;
    }

    public boolean esDe(FamiliaUnidad otra) {
        return familia != null && familia == otra;
    }

    /** Cantidad en esta unidad → unidad base (2,5 kg → 2500 g). */
    public BigDecimal aBase(BigDecimal cantidad) {
        return cantidad.multiply(factor);
    }

    /** Cantidad en unidad base → esta unidad (2500 g → 2,5 kg). */
    public BigDecimal desdeBase(BigDecimal cantidadBase, int decimales) {
        return cantidadBase.divide(factor, decimales, RoundingMode.HALF_UP);
    }

    /** Cantidad base mostrada en esta unidad, con coma decimal: 2500 g → "2,5 kg". */
    public String texto(BigDecimal cantidadBase) {
        String numero = desdeBase(cantidadBase, 3).stripTrailingZeros().toPlainString().replace('.', ',');
        return numero + " " + abreviatura;
    }

    /** Unidades de una familia, de la más chica a la más grande. */
    public static List<UnidadMedida> de(FamiliaUnidad familia) {
        return Arrays.stream(values()).filter(u -> u.familia == familia).toList();
    }
}
