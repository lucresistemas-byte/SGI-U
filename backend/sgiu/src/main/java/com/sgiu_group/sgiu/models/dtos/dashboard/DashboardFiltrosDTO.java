package com.sgiu_group.sgiu.models.dtos.dashboard;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDate;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class DashboardFiltrosDTO {
    private LocalDate fechaDesde;
    private LocalDate fechaHasta;
    private Long metodoPagoId;
    private Long productoId;
    private String tipoTransaccion;
    private String tipoProducto;

    public DashboardFiltrosDTO(LocalDate fechaDesde, LocalDate fechaHasta,
                                Long metodoPagoId, Long productoId,
                                String tipoTransaccion) {
        this(fechaDesde, fechaHasta, metodoPagoId, productoId, tipoTransaccion, null);
    }

    public DashboardFiltrosDTO(LocalDate fechaDesde, LocalDate fechaHasta,
                                Long metodoPagoId, Long productoId,
                                String tipoTransaccion, String tipoProducto) {
        this.tipoProducto = tipoProducto;
        this.fechaDesde = fechaDesde;
        this.fechaHasta = fechaHasta;
        this.metodoPagoId = metodoPagoId;
        this.productoId = productoId;
        this.tipoTransaccion = tipoTransaccion;
    }

    public LocalDate getFechaDesde() { return fechaDesde; }
    public LocalDate getFechaHasta() { return fechaHasta; }
    public Long getMetodoPagoId() { return metodoPagoId; }
    public Long getProductoId() { return productoId; }
    public String getTipoTransaccion() { return tipoTransaccion; }
    public String getTipoProducto() { return tipoProducto; }
}
