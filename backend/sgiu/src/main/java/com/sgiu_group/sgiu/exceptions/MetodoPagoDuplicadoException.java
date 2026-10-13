package com.sgiu_group.sgiu.exceptions;

/** Ya existe un método de pago con ese nombre (409). */
public class MetodoPagoDuplicadoException extends RuntimeException {
    public MetodoPagoDuplicadoException(String message) {
        super(message);
    }
}
