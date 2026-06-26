package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;

public class VentasMetodoPagoDTO {
    private String metodoPago;
    private Long cantidadVentas;
    private BigDecimal montoTotal;

    public VentasMetodoPagoDTO(String metodoPago, Long cantidadVentas, BigDecimal montoTotal) {
        this.metodoPago = metodoPago;
        this.cantidadVentas = cantidadVentas;
        this.montoTotal = montoTotal;
    }

    public String getMetodoPago() { return metodoPago; }
    public Long getCantidadVentas() { return cantidadVentas; }
    public BigDecimal getMontoTotal() { return montoTotal; }
}
