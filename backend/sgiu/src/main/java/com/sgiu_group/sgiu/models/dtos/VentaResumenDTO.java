package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Resumen de una venta para el listado del frontend (R-15).
 */
public record VentaResumenDTO(
    Long id,
    LocalDateTime fechaHora,
    BigDecimal total,
    Boolean anulada,
    String motivoAnulacion,
    LocalDateTime fechaHoraAnulacion,
    String anuladoPorUsuario,
    List<LineaResumenDTO> lineas,
    List<PagoResumenDTO> pagos
) {
    public record LineaResumenDTO(
        String codigoProducto,
        String nombreProducto,
        Integer cantidad,
        BigDecimal precioUnitario,
        BigDecimal subtotal
    ) {}

    public record PagoResumenDTO(
        Long metodoPagoId,
        String metodoPagoNombre,
        BigDecimal monto
    ) {}
}
