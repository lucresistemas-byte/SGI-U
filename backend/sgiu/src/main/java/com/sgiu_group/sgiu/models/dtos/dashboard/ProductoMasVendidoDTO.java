package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;

public class ProductoMasVendidoDTO {
    private Long productoId;
    private String nombre;
    private Long cantidadVendida;
    private BigDecimal montoTotal;
    /** Costo congelado de lo vendido y ganancia (montoTotal − costo); null si no se calculó. */
    private BigDecimal costo;
    private BigDecimal ganancia;

    public ProductoMasVendidoDTO(Long productoId, String nombre,
                                  Long cantidadVendida, BigDecimal montoTotal) {
        this.productoId = productoId;
        this.nombre = nombre;
        this.cantidadVendida = cantidadVendida;
        this.montoTotal = montoTotal;
    }

    public ProductoMasVendidoDTO(Long productoId, String nombre, Long cantidadVendida,
                                  BigDecimal montoTotal, BigDecimal costo) {
        this(productoId, nombre, cantidadVendida, montoTotal);
        this.costo = costo;
        this.ganancia = montoTotal.subtract(costo);
    }

    public Long getProductoId() { return productoId; }
    public String getNombre() { return nombre; }
    public Long getCantidadVendida() { return cantidadVendida; }
    public BigDecimal getMontoTotal() { return montoTotal; }
    public BigDecimal getCosto() { return costo; }
    public BigDecimal getGanancia() { return ganancia; }
}
