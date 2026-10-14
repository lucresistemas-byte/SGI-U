package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
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

    /** Cuánto rinde la receta (p. ej. 8 porciones, 24 alfajores); mayor a cero. */
    @Column(nullable = false, precision = 10, scale = 3)
    private BigDecimal rinde = BigDecimal.ONE;

    /** Qué rinde: "porciones", "unidades"... (en las preparaciones base, la abreviatura: "g"). */
    @Column(name = "rinde_unidad", nullable = false, length = 30)
    private String rindeUnidad = "unidades";

    /**
     * Preparación base: unidad del rinde, de peso o volumen ("rinde 800 g").
     * null en los elaborados que se venden (rinden unidades o porciones).
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "rinde_unidad_medida", length = 20)
    private UnidadMedida rindeUnidadMedida;

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
}
