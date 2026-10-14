package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Una tanda producida de un elaborado o un paquete (carga de stock que descuenta sus componentes). */
@Entity
@Table(name = "producciones")
@Getter
@Setter
@NoArgsConstructor
public class Produccion extends BaseEntity {

    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    @JoinColumn(name = "articulo_id", nullable = false, foreignKey = @ForeignKey(name = "fk_produccion_articulo"))
    private EspProducto articulo;

    @Column(nullable = false, precision = 14, scale = 3)
    private BigDecimal cantidad;

    /** Costo unitario del producto al producir (congelado). */
    @Column(name = "costo_unitario", nullable = false, precision = 14, scale = 4)
    private BigDecimal costoUnitario;

    @Column(name = "con_faltantes", nullable = false)
    @org.hibernate.annotations.ColumnDefault("false")
    private boolean conFaltantes;

    @Column(length = 2000)
    private String faltantes;

    @Column(length = 255)
    private String motivo;

    @Column(nullable = false)
    private LocalDateTime fecha;

    @Column(length = 100)
    private String usuario;
}
