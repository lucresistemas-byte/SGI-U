package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/** Una fila del armado de un paquete: un insumo con su cantidad (caja, 1 m de cinta...). */
@Entity
@Table(name = "paquetes_armado")
@Getter
@Setter
@NoArgsConstructor
public class PaqueteArmado extends BaseEntity {

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "paquete_id", nullable = false, foreignKey = @ForeignKey(name = "fk_paquete_armado_paquete"))
    private EspProducto paquete;

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "articulo_id", nullable = false, foreignKey = @ForeignKey(name = "fk_paquete_armado_articulo"))
    private EspProducto articulo;

    /** En la unidad elegida. */
    @Column(nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidad;

    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_medida", nullable = false, length = 20)
    private UnidadMedida unidadMedida;

    /** En la unidad base del insumo. */
    @Column(name = "cantidad_base", nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidadBase;

    public PaqueteArmado(EspProducto paquete, EspProducto articulo, BigDecimal cantidad, UnidadMedida unidadMedida) {
        this.paquete = paquete;
        this.articulo = articulo;
        this.cantidad = cantidad;
        this.unidadMedida = unidadMedida;
        this.cantidadBase = unidadMedida.aBase(cantidad);
    }
}
