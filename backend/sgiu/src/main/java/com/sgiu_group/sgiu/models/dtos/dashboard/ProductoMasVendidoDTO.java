package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;

public class ProductoMasVendidoDTO {
    private Long productoId;
    private String nombre;
    private Long cantidadVendida;
    private BigDecimal montoTotal;

    public ProductoMasVendidoDTO(Long productoId, String nombre,
                                  Long cantidadVendida, BigDecimal montoTotal) {
        this.productoId = productoId;
        this.nombre = nombre;
        this.cantidadVendida = cantidadVendida;
        this.montoTotal = montoTotal;
    }

    public Long getProductoId() { return productoId; }
    public String getNombre() { return nombre; }
    public Long getCantidadVendida() { return cantidadVendida; }
    public BigDecimal getMontoTotal() { return montoTotal; }
}
