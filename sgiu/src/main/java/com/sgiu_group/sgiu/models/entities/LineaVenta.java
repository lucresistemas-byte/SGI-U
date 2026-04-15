package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "lineas_venta")
public class LineaVenta extends BaseEntity {

    @ManyToOne(optional = false)
    @JoinColumn(name = "venta_id", nullable = false,
                foreignKey = @ForeignKey(name = "fk_linea_venta_venta"))
    private Venta venta;

    @ManyToOne(optional = false)
    @JoinColumn(name = "articulo_id", nullable = false,
                foreignKey = @ForeignKey(name = "fk_linea_venta_articulo"))
    private ArticuloStock articulo;

    @Column(nullable = false)
    private Integer cantidad;

    @Column(name = "precio_unitario", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioUnitario;

    public LineaVenta() {}

    public LineaVenta(Venta venta, ArticuloStock articulo, Integer cantidad, BigDecimal precioUnitario) {
        this.venta = venta;
        this.articulo = articulo;
        this.cantidad = cantidad;
        this.precioUnitario = precioUnitario;
    }

    public Venta getVenta() {
        return venta;
    }

    public void setVenta(Venta venta) {
        this.venta = venta;
    }

    public ArticuloStock getArticulo() {
        return articulo;
    }

    public void setArticulo(ArticuloStock articulo) {
        this.articulo = articulo;
    }

    public Integer getCantidad() {
        return cantidad;
    }

    public void setCantidad(Integer cantidad) {
        if (cantidad <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor a cero");
        }
        this.cantidad = cantidad;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        if (precioUnitario.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("El precio no puede ser negativo");
        }
        this.precioUnitario = precioUnitario;
    }
}
