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

    // Agregado por CU02: Nombre del producto
    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(name = "precio_unitario", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioUnitario;

    // Agregado por RN08: Atributo para baja lógica
    @Column(nullable = false)
    private boolean activo;

    public EspProducto() {
        // Por defecto, un producto nuevo nace activo
        this.activo = true;
    }

    public EspProducto(String codigo, String nombre, BigDecimal precioUnitario) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.precioUnitario = precioUnitario;
        this.activo = true;
    }

    // --- GETTERS Y SETTERS ---

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        this.precioUnitario = precioUnitario;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}