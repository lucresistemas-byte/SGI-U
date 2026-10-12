package com.sgiu_group.sgiu.models.dtos;

import com.sgiu_group.sgiu.models.entities.MetodoPago;

public record MetodoPagoDTO(Long id, String nombre, boolean activo, boolean fijo, int orden) {

    public static MetodoPagoDTO de(MetodoPago m) {
        return new MetodoPagoDTO(m.getId(), m.getNombre(), m.isActivo(), m.isFijo(), m.getOrden());
    }
}
