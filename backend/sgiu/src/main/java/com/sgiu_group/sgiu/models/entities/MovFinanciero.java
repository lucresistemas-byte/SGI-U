package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

import java.math.BigDecimal;


@Entity
@Table(name = "movimientos_financieros")
public class MovFinanciero extends BaseEntity {

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @Column(nullable = false, length = 20)
    private String tipo; // INGRESO o EGRESO

    @Column(length = 255)
    private String descripcion;

    @ManyToOne
    @JoinColumn(name = "pago_id",
                foreignKey = @ForeignKey(name = "fk_mov_financiero_pago"))
    private PagoVenta pago;

    public MovFinanciero() {}

    public MovFinanciero(BigDecimal monto, String tipo, String descripcion, PagoVenta pago) {
        this.monto = monto;
        this.tipo = tipo;
        this.descripcion = descripcion;
        this.pago = pago;
    }

    public BigDecimal getMonto() {
        return monto;
    }

    public void setMonto(BigDecimal monto) {
        if (monto.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("El monto debe ser mayor a cero");
        }
        this.monto = monto;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        if (!"INGRESO".equals(tipo) && !"EGRESO".equals(tipo)) {
            throw new IllegalArgumentException("El tipo debe ser INGRESO o EGRESO");
        }
        this.tipo = tipo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public PagoVenta getPago() {
        return pago;
    }

    public void setPago(PagoVenta pago) {
        this.pago = pago;
    }
}