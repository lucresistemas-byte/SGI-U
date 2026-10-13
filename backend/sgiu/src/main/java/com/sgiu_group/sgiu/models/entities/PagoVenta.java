package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

import java.math.BigDecimal;


@Entity
@Table(name = "pagos_venta")
public class PagoVenta extends BaseEntity {

    @ManyToOne(optional = false)
    @JoinColumn(name = "venta_id", nullable = false,
                foreignKey = @ForeignKey(name = "fk_pago_venta"))
    private Venta venta;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @ManyToOne(optional = false)
    @JoinColumn(name = "metodo_pago_id", nullable = false,
                foreignKey = @ForeignKey(name = "fk_pago_venta_metodo"))
    private MetodoPago metodoPago;

    public PagoVenta() {}

    public PagoVenta(Venta venta, BigDecimal monto, MetodoPago metodoPago) {
        this.venta = venta;
        this.monto = monto;
        this.metodoPago = metodoPago;
    }

    public Venta getVenta() {
        return venta;
    }

    public void setVenta(Venta venta) {
        this.venta = venta;
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

    public MetodoPago getMetodoPago() {
        return metodoPago;
    }

    public void setMetodoPago(MetodoPago metodoPago) {
        if (metodoPago == null) {
            throw new IllegalArgumentException("El método de pago es obligatorio");
        }
        this.metodoPago = metodoPago;
    }
}
