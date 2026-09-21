package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(
    name = "materias_primas",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_materia_prima_codigo", columnNames = "codigo")
    }
)
@Getter
@Setter
@NoArgsConstructor
public class MateriaPrima extends BaseEntity {

    @Column(nullable = false, length = 50)
    private String codigo;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(name = "costo_unitario", nullable = false, precision = 10, scale = 2)
    private BigDecimal costoUnitario = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_medida", length = 20, nullable = false)
    private UnidadMedida unidadMedida = UnidadMedida.UNIDAD;

    @Column(name = "stock_actual", nullable = false)
    private Integer stockActual = 0;

    @Column(name = "stock_minimo", nullable = false)
    private Integer stockMinimo = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "esp_producto_id", foreignKey = @ForeignKey(name = "fk_materia_prima_esp_producto"))
    private EspProducto producto;

    @Column(nullable = false)
    private boolean activo = true;

    public MateriaPrima(String codigo, String nombre, BigDecimal costoUnitario, UnidadMedida unidadMedida, Integer stockActual, Integer stockMinimo) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.costoUnitario = costoUnitario != null ? costoUnitario : BigDecimal.ZERO;
        this.unidadMedida = unidadMedida != null ? unidadMedida : UnidadMedida.UNIDAD;
        this.stockActual = stockActual != null ? stockActual : 0;
        this.stockMinimo = stockMinimo != null ? stockMinimo : 0;
        this.activo = true;
    }
}
