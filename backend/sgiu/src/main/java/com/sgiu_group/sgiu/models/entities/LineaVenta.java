package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "lineas_venta")
public class LineaVenta extends BaseEntity {

    @ManyToOne(optional = false)
    @JoinColumn(name = "id_venta", nullable = false, 
                foreignKey = @ForeignKey(name = "fk_linea_venta_venta"))
    private Venta venta;

    // CORRECCIÓN: Relación con EspProducto (Catálogo) en lugar de ArticuloStock
    @ManyToOne(optional = false)
    @JoinColumn(name = "codigo_producto", nullable = false, 
                foreignKey = @ForeignKey(name = "fk_linea_venta_producto"))
    private EspProducto producto;

    @Column(nullable = false)
    private Integer cantidad;

    // Campo agregado según el diagrama de datos
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotal;

    // El precio unitario se mantiene para persistir el valor histórico al momento de la venta
    @Column(name = "precio_unitario", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioUnitario;

    public LineaVenta() {}

    public LineaVenta(Venta venta, EspProducto producto, Integer cantidad) {
        this.venta = venta;
        this.producto = producto;
        this.cantidad = cantidad;
        this.precioUnitario = producto.getPrecioUnitario();
        calcularSubtotal();
    }

    // Método para asegurar que el subtotal siempre sea correcto
    public void calcularSubtotal() {
        if (this.precioUnitario != null && this.cantidad != null) {
            this.subtotal = this.precioUnitario.multiply(new BigDecimal(this.cantidad));
        }
    }

    // --- GETTERS Y SETTERS ---

    public Venta getVenta() {
        return venta;
    }

    public void setVenta(Venta venta) {
        this.venta = venta;
    }

    public EspProducto getProducto() {
        return producto;
    }

    public void setProducto(EspProducto producto) {
        this.producto = producto;
        if (producto != null) {
            this.precioUnitario = producto.getPrecioUnitario();
        }
    }

    public Integer getCantidad() {
        return cantidad;
    }

    public void setCantidad(Integer cantidad) {
        if (cantidad <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor a cero");
        }
        this.cantidad = cantidad;
        calcularSubtotal();
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        this.precioUnitario = precioUnitario;
        calcularSubtotal();
    }

    public BigDecimal getSubtotal() {
        return subtotal;
    }

    // El subtotal no suele tener setter público directo para evitar inconsistencias
}