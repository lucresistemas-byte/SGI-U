package com.sgiu_group.sgiu.models.dtos;

public record CambioPasswordRequestDTO(
    String passwordActual,
    String passwordNueva
) {}
