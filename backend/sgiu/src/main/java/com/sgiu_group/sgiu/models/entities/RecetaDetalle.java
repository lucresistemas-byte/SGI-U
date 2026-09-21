package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Entity
@Table(name = "recetas_detalles")
@Getter
@Setter
@NoArgsConstructor
public class RecetaDetalle extends BaseEntity {

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "receta_id", nullable = false, foreignKey = @ForeignKey(name = "fk_receta_detalle_receta"))
    @JsonIgnore
    private Receta receta;

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "materia_prima_id", nullable = false, foreignKey = @ForeignKey(name = "fk_receta_detalle_materia_prima"))
    private MateriaPrima materiaPrima;

    @Column(nullable = false, precision = 10, scale = 3)
    private BigDecimal cantidad;

    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_medida", length = 20, nullable = false)
    private UnidadMedida unidadMedida = UnidadMedida.UNIDAD;

    public RecetaDetalle(Receta receta, MateriaPrima materiaPrima, BigDecimal cantidad, UnidadMedida unidadMedida) {
        this.receta = receta;
        this.materiaPrima = materiaPrima;
        this.cantidad = cantidad;
        this.unidadMedida = unidadMedida != null ? unidadMedida : (materiaPrima != null ? materiaPrima.getUnidadMedida() : UnidadMedida.UNIDAD);
    }

    public BigDecimal calcularSubtotal() {
        if (materiaPrima != null && materiaPrima.getCostoUnitario() != null && cantidad != null) {
            return materiaPrima.getCostoUnitario().multiply(cantidad).setScale(2, RoundingMode.HALF_UP);
        }
        return BigDecimal.ZERO;
    }
}
