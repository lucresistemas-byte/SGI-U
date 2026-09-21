package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "recetas")
@Getter
@Setter
@NoArgsConstructor
public class Receta extends BaseEntity {

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "esp_producto_id", nullable = false, unique = true, foreignKey = @ForeignKey(name = "fk_receta_esp_producto"))
    private EspProducto producto;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(length = 255)
    private String descripcion;

    @Column(name = "costos_adicionales", precision = 10, scale = 2)
    private BigDecimal costosAdicionales = BigDecimal.ZERO;

    @OneToMany(mappedBy = "receta", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<RecetaDetalle> detalles = new ArrayList<>();

    @Column(nullable = false)
    private boolean activo = true;

    public Receta(EspProducto producto, String nombre, String descripcion, BigDecimal costosAdicionales) {
        this.producto = producto;
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.costosAdicionales = costosAdicionales != null ? costosAdicionales : BigDecimal.ZERO;
        this.activo = true;
    }

    public void addDetalle(RecetaDetalle detalle) {
        detalles.add(detalle);
        detalle.setReceta(this);
    }

    public void removeDetalle(RecetaDetalle detalle) {
        detalles.remove(detalle);
        detalle.setReceta(null);
    }

    public BigDecimal calcularCostoTotal() {
        BigDecimal total = costosAdicionales != null ? costosAdicionales : BigDecimal.ZERO;
        if (detalles != null) {
            for (RecetaDetalle d : detalles) {
                if (d.getMateriaPrima() != null && d.getCantidad() != null) {
                    BigDecimal subtotal = d.getMateriaPrima().getCostoUnitario().multiply(d.getCantidad());
                    total = total.add(subtotal);
                }
            }
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }
}
