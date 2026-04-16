package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.util.List;

import java.util.ArrayList;

@Entity
@Table(name = "ventas")
public class Venta extends BaseEntity {

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @OneToMany(
        mappedBy = "venta",
        cascade = CascadeType.ALL,
        orphanRemoval = true
    )
    private List<LineaVenta> lineas = new ArrayList<>();

    public Venta() {}

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }

    public List<LineaVenta> getLineas() {
        return lineas;
    }

    public void setLineas(List<LineaVenta> lineas) {
        this.lineas = lineas;
    }

    // 🔥 MÉTODOS AUXILIARES (MUY IMPORTANTES)
    public void addLinea(LineaVenta linea) {
        lineas.add(linea);
        linea.setVenta(this);
    }

    public void removeLinea(LineaVenta linea) {
        lineas.remove(linea);
        linea.setVenta(null);
    }
}