package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Materia prima o insumo. Pertenece a una familia de unidades: el stock y el
 * costo se guardan en la unidad base de la familia (gramo, mililitro,
 * centímetro o unidad). La unidad de medida es solo para mostrar.
 */
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

    /** MATERIA_PRIMA, INSUMO o REVENTA_MATERIA_PRIMA; define el prefijo del código. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TipoArticulo tipo = TipoArticulo.MATERIA_PRIMA;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private FamiliaUnidad familia = FamiliaUnidad.UNIDAD;

    /** Unidad en la que se muestra (de la familia; puede cambiarse dentro de ella). */
    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_medida", length = 20, nullable = false)
    private UnidadMedida unidadMedida = UnidadMedida.UNIDAD;

    /** Costo por unidad base, con 4 decimales (p. ej. $1,2000 por gramo). */
    @Column(name = "costo_unidad_base", nullable = false, precision = 14, scale = 4)
    private BigDecimal costoUnidadBase = BigDecimal.ZERO;

    /** Stock en unidad base. */
    @Column(name = "stock_actual", nullable = false, precision = 14, scale = 3)
    private BigDecimal stockActual = BigDecimal.ZERO;

    /** Stock mínimo en unidad base. */
    @Column(name = "stock_minimo", nullable = false, precision = 14, scale = 3)
    private BigDecimal stockMinimo = BigDecimal.ZERO;

    // Presentación de compra (p. ej. "Bolsa 25 kg": 25 KILO a $30.000), de
    // la que sale el costo por unidad base. Se guarda para poder editarla.
    @Column(name = "presentacion_descripcion", length = 100)
    private String presentacionDescripcion;

    @Column(name = "presentacion_cantidad", precision = 14, scale = 3)
    private BigDecimal presentacionCantidad;

    @Enumerated(EnumType.STRING)
    @Column(name = "presentacion_unidad", length = 20)
    private UnidadMedida presentacionUnidad;

    @Column(name = "presentacion_precio", precision = 12, scale = 2)
    private BigDecimal presentacionPrecio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "esp_producto_id", foreignKey = @ForeignKey(name = "fk_materia_prima_esp_producto"))
    private EspProducto producto;

    @Column(nullable = false)
    private boolean activo = true;

    /**
     * Costo y stock expresados en {@code unidadMedida} (p. ej. $1000 el kilo y
     * 10 kilos): se guardan en la unidad base (1 por gramo, 10000 g).
     */
    public MateriaPrima(String codigo, String nombre, BigDecimal costoPorUnidad, UnidadMedida unidadMedida,
                        Integer stockActual, Integer stockMinimo) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.unidadMedida = unidadMedida != null && unidadMedida.getFamilia() != null ? unidadMedida : UnidadMedida.UNIDAD;
        this.familia = this.unidadMedida.getFamilia();
        BigDecimal costo = costoPorUnidad != null ? costoPorUnidad : BigDecimal.ZERO;
        this.costoUnidadBase = costo.divide(this.unidadMedida.getFactor(), 4, RoundingMode.HALF_UP);
        this.stockActual = this.unidadMedida.aBase(BigDecimal.valueOf(stockActual != null ? stockActual : 0));
        this.stockMinimo = this.unidadMedida.aBase(BigDecimal.valueOf(stockMinimo != null ? stockMinimo : 0));
        this.activo = true;
    }

    /** Costo de una unidad dada de la familia (p. ej. el kilo). */
    public BigDecimal costoPor(UnidadMedida unidad) {
        return costoUnidadBase.multiply(unidad.getFactor());
    }

    /** Costo por la unidad en que se muestra, con 4 decimales. */
    public BigDecimal getCostoUnitario() {
        return costoPor(unidadMedida).setScale(4, RoundingMode.HALF_UP);
    }
}
