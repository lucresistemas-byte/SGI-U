package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

/** Venta registrada: total, vuelto (en efectivo) y lo cobrado por método. */
public record VentaResponseDTO(
    Long id,
    BigDecimal total,
    BigDecimal vuelto,
    List<PagoRegistradoDTO> pagos
) {
    public record PagoRegistradoDTO(Long metodoPagoId, String metodoPago, BigDecimal monto) {}
}
