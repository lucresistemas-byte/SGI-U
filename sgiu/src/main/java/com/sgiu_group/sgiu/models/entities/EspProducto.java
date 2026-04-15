package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(
    name = "esp_productos",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_esp_producto_codigo", columnNames = "codigo")
    }
)
public class EspProducto extends BaseEntity {

    @Column(nullable = false, length = 50)
    private String codigo;

    @Column(name = "precio_unitario", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioUnitario;

    public EspProducto() {}

    public EspProducto(String codigo, BigDecimal precioUnitario) {
        this.codigo = codigo;
        this.precioUnitario = precioUnitario;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        this.precioUnitario = precioUnitario;
    }
}