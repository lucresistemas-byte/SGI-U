package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Venta del POS. Se cobra con una o varias líneas de pago ({@link #pagos})
 * que tienen que cubrir el total. Si no se envían pagos, se cobra el total
 * con {@link #metodoPago} (o Efectivo): el camino de una venta simple.
 * <p>
 * {@link #tokenIdempotencia}: token generado por el frontend por cada cobro;
 * si la red o el reintento de stock repiten la petición con el mismo token,
 * el backend no registra una venta duplicada.
 */
public record VentaRequestDTO(
    Long metodoPago,
    @Valid @NotEmpty(message = "La venta debe tener al menos una línea.")
    List<LineaVentaDTO> lineas,
    @Valid
    List<PagoVentaRequestDTO> pagos,
    @Size(max = 64, message = "El token de idempotencia no puede superar 64 caracteres.")
    String tokenIdempotencia
) {
    public VentaRequestDTO(Long metodoPago, List<LineaVentaDTO> lineas) {
        this(metodoPago, lineas, null, null);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, String metodoPago) {
        this(1L, lineas, null, null);
    }

    public VentaRequestDTO(List<LineaVentaDTO> lineas, Long metodoPago) {
        this(metodoPago, lineas, null, null);
    }

    public VentaRequestDTO(Long metodoPago, List<LineaVentaDTO> lineas, List<PagoVentaRequestDTO> pagos) {
        this(metodoPago, lineas, pagos, null);
    }
}
