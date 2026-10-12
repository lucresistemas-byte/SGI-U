package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/**
 * Venta del POS. Se cobra con una o varias líneas de pago ({@link #pagos})
 * que tienen que cubrir el total. Si no se envían pagos, se cobra el total
 * con {@link #metodoPago} (o Efectivo): el camino de una venta simple.
 */
public record VentaRequestDTO(
    Long metodoPago,
    @Valid @NotEmpty(message = "La venta debe tener al menos una línea.")
    List<LineaVentaDTO> lineas,
    @Valid
    List<PagoVentaRequestDTO> pagos
) {
    public VentaRequestDTO(Long metodoPago, List<LineaVentaDTO> lineas) {
        this(metodoPago, lineas, null);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, String metodoPago) {
        this(1L, lineas, null);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, Long metodoPago) {
        this(metodoPago, lineas, null);
    }
}
