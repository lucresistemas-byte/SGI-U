package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotNull;

/** Cuerpo de PATCH .../estado: activar o desactivar (nada se elimina). */
public record EstadoRequestDTO(
    @NotNull(message = "Indique si se activa o desactiva (activo: true/false).")
    Boolean activo
) {}
