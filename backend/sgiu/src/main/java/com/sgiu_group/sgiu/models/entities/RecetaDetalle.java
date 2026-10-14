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

    /** Materia prima, insumo o reventa + materia prima del catálogo. */
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "articulo_id", nullable = false, foreignKey = @ForeignKey(name = "fk_receta_detalle_articulo"))
    private EspProducto articulo;

    /** Cantidad en la unidad elegida en el armador. */
    @Column(nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidad;

    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_medida", length = 20, nullable = false)
    private UnidadMedida unidadMedida = UnidadMedida.UNIDAD;

    /** Cantidad en la unidad base de la familia del insumo (200 g, 150 ml, 50 cm). */
    @Column(name = "cantidad_base", nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidadBase = BigDecimal.ZERO;

    public RecetaDetalle(Receta receta, EspProducto articulo, BigDecimal cantidad, UnidadMedida unidadMedida) {
        this.receta = receta;
        this.articulo = articulo;
        this.cantidad = cantidad;
        this.unidadMedida = unidadMedida != null ? unidadMedida : (articulo != null ? articulo.getUnidadMedida() : UnidadMedida.UNIDAD);
        this.cantidadBase = cantidad != null && this.unidadMedida.getFamilia() != null
                ? this.unidadMedida.aBase(cantidad) : (cantidad != null ? cantidad : BigDecimal.ZERO);
    }

    /** Costo de la fila sin redondear: cantidad en unidad base × costo por unidad base. */
    public BigDecimal calcularCosto() {
        if (articulo == null || articulo.getCostoUnidadBase() == null || cantidadBase == null) {
            return BigDecimal.ZERO;
        }
        return articulo.getCostoUnidadBase().multiply(cantidadBase);
    }

    public BigDecimal calcularSubtotal() {
        return calcularCosto().setScale(2, RoundingMode.HALF_UP);
    }
}
