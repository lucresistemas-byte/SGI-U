package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.NotBlank;

public record CategoriaDTO(
    Long id,
    @NotBlank(message = "El nombre de la categoría es obligatorio.")
    String nombre,
    String descripcion,
    Boolean activo
) {
    public CategoriaDTO(String nombre, String descripcion) {
        this(null, nombre, descripcion, true);
    }
}
