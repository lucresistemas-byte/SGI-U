package com.sgiu_group.sgiu.models.dtos;

public record ConfiguracionDTO(
    String nombre,
    String codigoCliente,
    byte[] logo,
    String direccion,
    String telefono,
    String descripcion
) {}
