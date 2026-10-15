package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Un cambio de stock de un artículo: cantidad firmada en unidad base y stock resultante. */
@Entity
@Table(name = "movimientos_stock")
@Getter
@Setter
@NoArgsConstructor
public class MovimientoStock extends BaseEntity {

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "articulo_id", nullable = false, foreignKey = @ForeignKey(name = "fk_movimiento_stock_articulo"))
    private EspProducto articulo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TipoMovimientoStock tipo;

    /** En unidad base: + entra, − sale. */
    @Column(nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidad;

    @Column(name = "stock_resultante", nullable = false, precision = 14, scale = 3)
    private BigDecimal stockResultante;

    @Column(length = 255)
    private String motivo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "produccion_id", foreignKey = @ForeignKey(name = "fk_movimiento_stock_produccion"))
    private Produccion produccion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "venta_id", foreignKey = @ForeignKey(name = "fk_movimiento_stock_venta"))
    private Venta venta;

    @Column(nullable = false)
    private LocalDateTime fecha;

    @Column(length = 100)
    private String usuario;
}
