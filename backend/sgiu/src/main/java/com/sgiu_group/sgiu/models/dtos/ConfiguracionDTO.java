package com.sgiu_group.sgiu.models.dtos;

public record ConfiguracionDTO(
    String nombre,
    String codigoCliente,
    byte[] logo,
    String direccion,
    String telefono,
    String descripcion,
    /** true = borrar el logo (sin logo, logo null significa "no cambiar"). */
    Boolean quitarLogo
) {
    public ConfiguracionDTO(String nombre, String codigoCliente, byte[] logo,
                            String direccion, String telefono, String descripcion) {
        this(nombre, codigoCliente, logo, direccion, telefono, descripcion, null);
    }
}
