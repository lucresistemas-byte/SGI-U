package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.math.RoundingMode;

@Entity
@Table(
    name = "esp_productos",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_esp_producto_codigo", columnNames = "codigo")
    }
)
public class EspProducto extends BaseEntity {

    @Column(nullable = false, length = 50)
    private String codigo;

    // Agregado por CU02: Nombre del producto
    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(name = "precio_unitario", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioUnitario;

    // MVP: Precio de costo
    @Column(name = "precio_costo", precision = 10, scale = 2)
    private BigDecimal precioCosto = BigDecimal.ZERO;

    // MVP: % de ganancia
    @Column(name = "porcentaje_ganancia", precision = 10, scale = 2)
    private BigDecimal porcentajeGanancia = BigDecimal.ZERO;

    // MVP: Unidad de medida configurable
    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_medida", length = 20)
    private UnidadMedida unidadMedida = UnidadMedida.UNIDAD;

    // MVP: Categorización de productos (nullable para retrocompatibilidad)
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "categoria_id", foreignKey = @ForeignKey(name = "fk_esp_producto_categoria"))
    private Categoria categoria;

    // Agregado por RN08: Atributo para baja lógica
    @Column(nullable = false)
    private boolean activo;

    public EspProducto() {
        this.activo = true;
        this.unidadMedida = UnidadMedida.UNIDAD;
        this.precioCosto = BigDecimal.ZERO;
        this.porcentajeGanancia = BigDecimal.ZERO;
    }

    public EspProducto(String codigo, String nombre, BigDecimal precioUnitario) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.precioUnitario = precioUnitario;
        this.precioCosto = BigDecimal.ZERO;
        this.porcentajeGanancia = BigDecimal.ZERO;
        this.unidadMedida = UnidadMedida.UNIDAD;
        this.activo = true;
    }

    public EspProducto(String codigo, String nombre, BigDecimal precioUnitario,
                       BigDecimal precioCosto, BigDecimal porcentajeGanancia,
                       UnidadMedida unidadMedida, Categoria categoria) {
        this.codigo = codigo;
        this.nombre = nombre;
        this.precioUnitario = precioUnitario;
        this.precioCosto = precioCosto != null ? precioCosto : BigDecimal.ZERO;
        this.porcentajeGanancia = porcentajeGanancia != null ? porcentajeGanancia : BigDecimal.ZERO;
        this.unidadMedida = unidadMedida != null ? unidadMedida : UnidadMedida.UNIDAD;
        this.categoria = categoria;
        this.activo = true;
    }

    // --- MÉTODOS DE CÁLCULO ---

    public void recalcularMargenDesdePrecios() {
        if (precioCosto != null && precioCosto.compareTo(BigDecimal.ZERO) > 0 && precioUnitario != null) {
            this.porcentajeGanancia = precioUnitario.subtract(precioCosto)
                    .divide(precioCosto, 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"))
                    .setScale(2, RoundingMode.HALF_UP);
        } else {
            this.porcentajeGanancia = BigDecimal.ZERO;
        }
    }

    public void recalcularPrecioDesdeCostoYMargen() {
        if (precioCosto != null && porcentajeGanancia != null) {
            BigDecimal factor = BigDecimal.ONE.add(
                    porcentajeGanancia.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP)
            );
            this.precioUnitario = precioCosto.multiply(factor).setScale(2, RoundingMode.HALF_UP);
        }
    }

    // --- GETTERS Y SETTERS ---

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        this.precioUnitario = precioUnitario;
    }

    public BigDecimal getPrecioCosto() {
        return precioCosto;
    }

    public void setPrecioCosto(BigDecimal precioCosto) {
        this.precioCosto = precioCosto != null ? precioCosto : BigDecimal.ZERO;
    }

    public BigDecimal getPorcentajeGanancia() {
        return porcentajeGanancia;
    }

    public void setPorcentajeGanancia(BigDecimal porcentajeGanancia) {
        this.porcentajeGanancia = porcentajeGanancia != null ? porcentajeGanancia : BigDecimal.ZERO;
    }

    public UnidadMedida getUnidadMedida() {
        return unidadMedida;
    }

    public void setUnidadMedida(UnidadMedida unidadMedida) {
        this.unidadMedida = unidadMedida != null ? unidadMedida : UnidadMedida.UNIDAD;
    }

    public Categoria getCategoria() {
        return categoria;
    }

    public void setCategoria(Categoria categoria) {
        this.categoria = categoria;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}