package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.util.ArrayList;
import java.util.List;

public class DashboardGraficosDTO {
    private List<IngresosEgresosPorDiaDTO> ingresosVsEgresosPorDia = new ArrayList<>();
    private List<VentasMetodoPagoDTO> ventasPorMetodoPago = new ArrayList<>();
    private List<ProductoMasVendidoDTO> topProductosMasVendidos = new ArrayList<>();
    private List<EvolucionSaldoDTO> evolucionSaldoNeto = new ArrayList<>();
    private List<ProductoStockCriticoDTO> productosConMenorStock = new ArrayList<>();

    public List<IngresosEgresosPorDiaDTO> getIngresosVsEgresosPorDia() { return ingresosVsEgresosPorDia; }
    public List<VentasMetodoPagoDTO> getVentasPorMetodoPago() { return ventasPorMetodoPago; }
    public List<ProductoMasVendidoDTO> getTopProductosMasVendidos() { return topProductosMasVendidos; }
    public List<EvolucionSaldoDTO> getEvolucionSaldoNeto() { return evolucionSaldoNeto; }
    public List<ProductoStockCriticoDTO> getProductosConMenorStock() { return productosConMenorStock; }

    public void setIngresosVsEgresosPorDia(List<IngresosEgresosPorDiaDTO> list) { this.ingresosVsEgresosPorDia = list; }
    public void setVentasPorMetodoPago(List<VentasMetodoPagoDTO> list) { this.ventasPorMetodoPago = list; }
    public void setTopProductosMasVendidos(List<ProductoMasVendidoDTO> list) { this.topProductosMasVendidos = list; }
    public void setEvolucionSaldoNeto(List<EvolucionSaldoDTO> list) { this.evolucionSaldoNeto = list; }
    public void setProductosConMenorStock(List<ProductoStockCriticoDTO> list) { this.productosConMenorStock = list; }
}
