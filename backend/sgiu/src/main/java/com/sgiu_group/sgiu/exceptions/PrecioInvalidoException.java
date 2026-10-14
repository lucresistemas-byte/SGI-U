package com.sgiu_group.sgiu.exceptions;

/** Precio de venta que no cumple las reglas (p. ej. a mano por debajo del % de ganancia). */
public class PrecioInvalidoException extends RuntimeException {
    public PrecioInvalidoException(String message) {
        super(message);
    }
}
