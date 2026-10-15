package com.sgiu_group.sgiu.exceptions;

import com.sgiu_group.sgiu.models.dtos.FaltanteDTO;

import java.util.List;

/**
 * Producir dejaría componentes en negativo: no se aplica nada y se avisa qué
 * falta. Sandra puede confirmar y producir igual.
 */
public class FaltanComponentesException extends RuntimeException {

    private final List<FaltanteDTO> faltantes;

    public FaltanComponentesException(String message, List<FaltanteDTO> faltantes) {
        super(message);
        this.faltantes = faltantes;
    }

    public List<FaltanteDTO> getFaltantes() {
        return faltantes;
    }
}
