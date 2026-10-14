package com.sgiu_group.sgiu.exceptions;

/** Dos cambios de stock simultáneos sobre el mismo artículo (bloqueo optimista) que no se resolvieron reintentando. */
public class ConflictoStockException extends RuntimeException {
    public ConflictoStockException(String message) {
        super(message);
    }
}
