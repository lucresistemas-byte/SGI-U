package com.sgiu_group.sgiu.models.dtos;

public record CategoriaDTO(
    Long id,
    String nombre,
    String descripcion,
    Boolean activo
) {
    public CategoriaDTO(String nombre, String descripcion) {
        this(null, nombre, descripcion, true);
    }
}
