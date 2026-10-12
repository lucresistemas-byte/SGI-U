package com.sgiu_group.sgiu.exceptions;

/** Datos de producto que no respetan las reglas del tipo de artículo (400). */
public class ProductoInvalidoException extends RuntimeException {
    public ProductoInvalidoException(String message) {
        super(message);
    }
}
