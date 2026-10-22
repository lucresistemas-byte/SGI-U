package com.sgiu_group.sgiu.models.dtos;

public record RecuperacionPasswordRequestDTO(
    String username,
    String claveRecuperacion,
    String passwordNueva
) {}
