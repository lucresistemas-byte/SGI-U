package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

@Entity
@Table(name = "articulos_stock")
public class ArticuloStock extends BaseEntity {

    @ManyToOne(optional = false)
    @JoinColumn(name = "esp_producto_id", nullable = false,
                foreignKey = @ForeignKey(name = "fk_articulo_stock_esp_producto"))
    private EspProducto espProducto;

    @Column(nullable = false)
    private Integer cantidad;

    @Column(name = "stock_minimo")
    private Integer stockMinimo = 0;

    public ArticuloStock() {}

    public ArticuloStock(EspProducto espProducto, Integer cantidad) {
        this.espProducto = espProducto;
        this.cantidad = cantidad;
        this.stockMinimo = 0;
    }

    public EspProducto getEspProducto() {
        return espProducto;
    }

    public void setEspProducto(EspProducto espProducto) {
        this.espProducto = espProducto;
    }

    public Integer getCantidad() {
        return cantidad;
    }

    public void setCantidad(Integer cantidad) {
        this.cantidad = cantidad;
    }

    public Integer getStockMinimo() {
        return stockMinimo;
    }

    public void setStockMinimo(Integer stockMinimo) {
        this.stockMinimo = stockMinimo;
    }
}
