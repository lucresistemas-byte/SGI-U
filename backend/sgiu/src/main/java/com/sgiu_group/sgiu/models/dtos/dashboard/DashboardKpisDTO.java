package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;

public class DashboardKpisDTO {
    private BigDecimal ingresosPeriodo;
    private BigDecimal egresosPeriodo;
    private BigDecimal saldoNeto;
    private BigDecimal margenNetoPorcentaje;
    private Long cantidadVentas;
    private BigDecimal ticketPromedio;
    private ProductoMasVendidoDTO productoMasVendido;
    private Long cantidadProductosStockBajo;

    public DashboardKpisDTO(BigDecimal ingresosPeriodo, BigDecimal egresosPeriodo,
                             BigDecimal saldoNeto, BigDecimal margenNetoPorcentaje,
                             Long cantidadVentas, BigDecimal ticketPromedio,
                             ProductoMasVendidoDTO productoMasVendido,
                             Long cantidadProductosStockBajo) {
        this.ingresosPeriodo = ingresosPeriodo;
        this.egresosPeriodo = egresosPeriodo;
        this.saldoNeto = saldoNeto;
        this.margenNetoPorcentaje = margenNetoPorcentaje;
        this.cantidadVentas = cantidadVentas;
        this.ticketPromedio = ticketPromedio;
        this.productoMasVendido = productoMasVendido;
        this.cantidadProductosStockBajo = cantidadProductosStockBajo;
    }

    public BigDecimal getIngresosPeriodo() { return ingresosPeriodo; }
    public BigDecimal getEgresosPeriodo() { return egresosPeriodo; }
    public BigDecimal getSaldoNeto() { return saldoNeto; }
    public BigDecimal getMargenNetoPorcentaje() { return margenNetoPorcentaje; }
    public Long getCantidadVentas() { return cantidadVentas; }
    public BigDecimal getTicketPromedio() { return ticketPromedio; }
    public ProductoMasVendidoDTO getProductoMasVendido() { return productoMasVendido; }
    public Long getCantidadProductosStockBajo() { return cantidadProductosStockBajo; }
}
