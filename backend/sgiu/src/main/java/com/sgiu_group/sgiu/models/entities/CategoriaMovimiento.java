package com.sgiu_group.sgiu.models.entities;

import java.util.Arrays;
import java.util.List;

/**
 * Categorías válidas para dar de alta un movimiento, según su tipo. La columna
 * movimientos_financieros.categoria sigue siendo texto: los movimientos
 * anteriores conservan su valor y la validación aplica solo al crear.
 */
public enum CategoriaMovimiento {
    VENTA(TipoMovimiento.INGRESO),
    OTRO_INGRESO(TipoMovimiento.INGRESO),
    COMPRA(TipoMovimiento.EGRESO),
    SERVICIOS(TipoMovimiento.EGRESO),
    ALQUILER(TipoMovimiento.EGRESO),
    SUELDOS(TipoMovimiento.EGRESO),
    OTRO(TipoMovimiento.EGRESO);

    private final TipoMovimiento tipo;

    CategoriaMovimiento(TipoMovimiento tipo) {
        this.tipo = tipo;
    }

    public TipoMovimiento getTipo() {
        return tipo;
    }

    public static List<CategoriaMovimiento> para(TipoMovimiento tipo) {
        return Arrays.stream(values()).filter(c -> c.tipo == tipo).toList();
    }
}
