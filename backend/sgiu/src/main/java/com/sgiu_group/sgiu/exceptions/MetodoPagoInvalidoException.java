package com.sgiu_group.sgiu.exceptions;

/** Operación no permitida sobre un método de pago (400). */
public class MetodoPagoInvalidoException extends RuntimeException {
    public MetodoPagoInvalidoException(String message) {
        super(message);
    }
}
