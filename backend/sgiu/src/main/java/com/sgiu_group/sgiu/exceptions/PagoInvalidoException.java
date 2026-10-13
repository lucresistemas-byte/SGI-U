package com.sgiu_group.sgiu.exceptions;

/** Los pagos de una venta no son válidos (no cubren el total, etc.): 400. */
public class PagoInvalidoException extends RuntimeException {
    public PagoInvalidoException(String message) {
        super(message);
    }
}
