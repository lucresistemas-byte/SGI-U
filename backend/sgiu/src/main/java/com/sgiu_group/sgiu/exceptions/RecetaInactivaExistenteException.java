package com.sgiu_group.sgiu.exceptions;

/**
 * Se intentó crear una receta para un producto que ya tiene una desactivada.
 * Como las recetas no se eliminan, hay que reactivar y editar la existente.
 */
public class RecetaInactivaExistenteException extends RuntimeException {

    private final Long recetaId;

    public RecetaInactivaExistenteException(String message, Long recetaId) {
        super(message);
        this.recetaId = recetaId;
    }

    public Long getRecetaId() {
        return recetaId;
    }
}
