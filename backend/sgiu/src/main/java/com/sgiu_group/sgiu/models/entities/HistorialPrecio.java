package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Un cambio de costo o de precio de venta de un artículo, con lo que lo causó. */
@Entity
@Table(name = "historial_precios")
@Getter
@Setter
@NoArgsConstructor
public class HistorialPrecio extends BaseEntity {

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "articulo_id", nullable = false, foreignKey = @ForeignKey(name = "fk_historial_precio_articulo"))
    private EspProducto articulo;

    @Column(name = "costo_anterior", precision = 14, scale = 4)
    private BigDecimal costoAnterior;

    @Column(name = "costo_nuevo", precision = 14, scale = 4)
    private BigDecimal costoNuevo;

    @Column(name = "precio_anterior", precision = 10, scale = 2)
    private BigDecimal precioAnterior;

    @Column(name = "precio_nuevo", precision = 10, scale = 2)
    private BigDecimal precioNuevo;

    @Enumerated(EnumType.STRING)
    @Column(name = "modo_precio", nullable = false, length = 20)
    private ModoPrecio modoPrecio;

    /** "Cambio de costo de Chocolate cobertura (MP-0005)". */
    @Column(nullable = false, length = 255)
    private String causa;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "causa_articulo_id", foreignKey = @ForeignKey(name = "fk_historial_precio_causa"))
    private EspProducto causaArticulo;

    @Column(nullable = false)
    private LocalDateTime fecha;

    @Column(length = 100)
    private String usuario;
}
