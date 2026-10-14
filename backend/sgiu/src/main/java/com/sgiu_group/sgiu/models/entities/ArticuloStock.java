package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(
    name = "articulos_stock",
    uniqueConstraints = @UniqueConstraint(name = "uk_articulo_stock_producto", columnNames = "esp_producto_id")
)
public class ArticuloStock extends BaseEntity {

    @ManyToOne(optional = false)
    @JoinColumn(name = "esp_producto_id", nullable = false,
                foreignKey = @ForeignKey(name = "fk_articulo_stock_esp_producto"))
    private EspProducto espProducto;

    /**
     * En unidad base: unidades para elaborados y reventa; gramos, mililitros,
     * centímetros o unidades para los artículos de materia prima.
     */
    @Column(nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidad = BigDecimal.ZERO;

    @Column(name = "stock_minimo", nullable = false, precision = 14, scale = 3)
    private BigDecimal stockMinimo = BigDecimal.ZERO;

    @Version
    @Column(nullable = false)
    private Long version;

    public ArticuloStock() {}

    public ArticuloStock(EspProducto espProducto, BigDecimal cantidad) {
        this.espProducto = espProducto;
        this.cantidad = cantidad;
        this.stockMinimo = BigDecimal.ZERO;
    }

    public ArticuloStock(EspProducto espProducto, long cantidad) {
        this(espProducto, BigDecimal.valueOf(cantidad));
    }

    public EspProducto getEspProducto() {
        return espProducto;
    }

    public void setEspProducto(EspProducto espProducto) {
        this.espProducto = espProducto;
    }

    public BigDecimal getCantidad() {
        return cantidad;
    }

    public void setCantidad(BigDecimal cantidad) {
        this.cantidad = cantidad;
    }

    public BigDecimal getStockMinimo() {
        return stockMinimo;
    }

    public void setStockMinimo(BigDecimal stockMinimo) {
        this.stockMinimo = stockMinimo != null ? stockMinimo : BigDecimal.ZERO;
    }
}
