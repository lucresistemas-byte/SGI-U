package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.util.ArrayList;
import java.util.List;

public class DashboardGraficosDTO {
    private List<IngresosEgresosPorDiaDTO> ingresosVsEgresosPorDia = new ArrayList<>();
    private List<VentasMetodoPagoDTO> ventasPorMetodoPago = new ArrayList<>();
    private List<ProductoGananciaDTO> topProductosPorGanancia = new ArrayList<>();
    private List<EvolucionSaldoDTO> evolucionSaldoNeto = new ArrayList<>();
    private List<ProductoStockCriticoDTO> productosConMenorStock = new ArrayList<>();

    public List<IngresosEgresosPorDiaDTO> getIngresosVsEgresosPorDia() { return ingresosVsEgresosPorDia; }
    public List<VentasMetodoPagoDTO> getVentasPorMetodoPago() { return ventasPorMetodoPago; }
    public List<ProductoGananciaDTO> getTopProductosPorGanancia() { return topProductosPorGanancia; }
    public List<EvolucionSaldoDTO> getEvolucionSaldoNeto() { return evolucionSaldoNeto; }
    public List<ProductoStockCriticoDTO> getProductosConMenorStock() { return productosConMenorStock; }
    public CategoriaMasVendidaDTO getCategoriaMasVendida() { return categoriaMasVendida; }

    private CategoriaMasVendidaDTO categoriaMasVendida;

    public void setIngresosVsEgresosPorDia(List<IngresosEgresosPorDiaDTO> list) { this.ingresosVsEgresosPorDia = list; }
    public void setVentasPorMetodoPago(List<VentasMetodoPagoDTO> list) { this.ventasPorMetodoPago = list; }
    public void setTopProductosPorGanancia(List<ProductoGananciaDTO> list) { this.topProductosPorGanancia = list; }
    public void setEvolucionSaldoNeto(List<EvolucionSaldoDTO> list) { this.evolucionSaldoNeto = list; }
    public void setProductosConMenorStock(List<ProductoStockCriticoDTO> list) { this.productosConMenorStock = list; }
    public void setCategoriaMasVendida(CategoriaMasVendidaDTO categoriaMasVendida) { this.categoriaMasVendida = categoriaMasVendida; }
}
