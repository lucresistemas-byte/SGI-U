package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/**
 * Venta del POS con soporte para token de idempotencia.
 * Se cobra con una o varias líneas de pago ({@link #pagos}) que tienen que cubrir el total.
 * Si no se envían pagos, se cobra el total con {@link #metodoPago} (o Efectivo).
 */
public record VentaRequestDTO(
    Long metodoPago,
    @Valid @NotEmpty(message = "La venta debe tener al menos una línea.")
    List<LineaVentaDTO> lineas,
    @Valid
    List<PagoVentaRequestDTO> pagos,
    String ventaIdempotencyToken
) {
    public VentaRequestDTO(Long metodoPago, List<LineaVentaDTO> lineas) {
        this(metodoPago, lineas, null, null);
    }

    public VentaRequestDTO(Long metodoPago, List<LineaVentaDTO> lineas, List<PagoVentaRequestDTO> pagos) {
        this(metodoPago, lineas, pagos, null);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, String metodoPago) {
        this(1L, lineas, null, null);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, Long metodoPago) {
        this(metodoPago, lineas, null, null);
    }
}
