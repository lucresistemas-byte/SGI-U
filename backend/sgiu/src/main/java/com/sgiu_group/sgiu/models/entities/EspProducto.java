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

    /** El comportamiento depende del tipo (ver TipoArticulo). */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TipoArticulo tipo = TipoArticulo.REVENTA;

    /** false = preparación base (un ELABORADO que nunca se vende). */
    @Column(nullable = false)
    private boolean vendible = true;

    /** Cómo se calcula el precio de venta (lo calcula CostosService). */
    @Enumerated(EnumType.STRING)
    @Column(name = "modo_precio", nullable = false, length = 20)
    @org.hibernate.annotations.ColumnDefault("'MARGEN'")
    private ModoPrecio modoPrecio = ModoPrecio.MARGEN;

    /** Paquetes: monto fijo que se suma al costo del armado. */
    @Column(name = "monto_fijo", precision = 10, scale = 2)
    private BigDecimal montoFijo;

    // --- Materia prima, insumo y reventa + materia prima ---
    // El stock (articulos_stock) y el costo se guardan en la unidad base de la
    // familia (gramo, mililitro, centímetro o unidad); unidadMedida es la
    // unidad en que se muestra.

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private FamiliaUnidad familia;

    /** Costo por unidad base, con 4 decimales (p. ej. $1,2000 por gramo). */
    @Column(name = "costo_unidad_base", precision = 14, scale = 4)
    private BigDecimal costoUnidadBase;

    // Presentación de compra (p. ej. "Bolsa 25 kg": 25 KILO a $30.000), de la
    // que sale el costo por unidad base.
    @Column(name = "presentacion_descripcion", length = 100)
    private String presentacionDescripcion;

    @Column(name = "presentacion_cantidad", precision = 14, scale = 3)
    private BigDecimal presentacionCantidad;

    @Enumerated(EnumType.STRING)
    @Column(name = "presentacion_unidad", length = 20)
    private UnidadMedida presentacionUnidad;

    @Column(name = "presentacion_precio", precision = 12, scale = 2)
    private BigDecimal presentacionPrecio;

    /** Reventa + materia prima: cómo se vende ("Caja"). */
    @Column(name = "venta_unidad_nombre", length = 50)
    private String ventaUnidadNombre;

    /** Reventa + materia prima: contenido de la unidad de venta en unidad base (100 g). */
    @Column(name = "venta_unidad_contenido", precision = 14, scale = 3)
    private BigDecimal ventaUnidadContenido;

    @Version
    @Column(nullable = false)
    private Long version;

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

    // --- MATERIA PRIMA ---

    public boolean esReventaMateriaPrima() {
        return tipo == TipoArticulo.REVENTA_MATERIA_PRIMA;
    }

    /** Cantidad de la presentación de compra en unidad base (un bulto de 12 cajas de 100 g = 1200 g). */
    public BigDecimal presentacionEnBase() {
        return presentacionCantidad == null || presentacionUnidad == null
                ? null : presentacionUnidad.aBase(presentacionCantidad);
    }

    /** Unidades enteras que se pueden vender con un stock dado (en unidad base). */
    public long unidadesDeVentaEn(BigDecimal stockBase) {
        if (stockBase == null || stockBase.signum() <= 0) {
            return 0;
        }
        if (!esReventaMateriaPrima()) {
            return stockBase.setScale(0, RoundingMode.FLOOR).longValue();
        }
        return stockBase.divide(ventaUnidadContenido, 0, RoundingMode.FLOOR).longValue();
    }

    /** Lo que queda suelto (en unidad base) después de las unidades de venta enteras. */
    public BigDecimal sueltoEn(BigDecimal stockBase) {
        if (!esReventaMateriaPrima() || stockBase == null || stockBase.signum() <= 0) {
            return BigDecimal.ZERO;
        }
        return stockBase.remainder(ventaUnidadContenido);
    }

    /** Stock que descuenta vender [unidades]: 1 caja = 100 g; otros tipos, 1 = 1. */
    public BigDecimal stockParaVender(long unidades) {
        BigDecimal cantidad = BigDecimal.valueOf(unidades);
        return esReventaMateriaPrima() ? cantidad.multiply(ventaUnidadContenido) : cantidad;
    }

    // --- GETTERS Y SETTERS ---

    public ModoPrecio getModoPrecio() {
        return modoPrecio;
    }

    public void setModoPrecio(ModoPrecio modoPrecio) {
        this.modoPrecio = modoPrecio != null ? modoPrecio : ModoPrecio.MARGEN;
    }

    public BigDecimal getMontoFijo() {
        return montoFijo;
    }

    public void setMontoFijo(BigDecimal montoFijo) {
        this.montoFijo = montoFijo;
    }

    public FamiliaUnidad getFamilia() {
        return familia;
    }

    public void setFamilia(FamiliaUnidad familia) {
        this.familia = familia;
    }

    public BigDecimal getCostoUnidadBase() {
        return costoUnidadBase;
    }

    public void setCostoUnidadBase(BigDecimal costoUnidadBase) {
        this.costoUnidadBase = costoUnidadBase;
    }

    public String getPresentacionDescripcion() {
        return presentacionDescripcion;
    }

    public void setPresentacionDescripcion(String presentacionDescripcion) {
        this.presentacionDescripcion = presentacionDescripcion;
    }

    public BigDecimal getPresentacionCantidad() {
        return presentacionCantidad;
    }

    public void setPresentacionCantidad(BigDecimal presentacionCantidad) {
        this.presentacionCantidad = presentacionCantidad;
    }

    public UnidadMedida getPresentacionUnidad() {
        return presentacionUnidad;
    }

    public void setPresentacionUnidad(UnidadMedida presentacionUnidad) {
        this.presentacionUnidad = presentacionUnidad;
    }

    public BigDecimal getPresentacionPrecio() {
        return presentacionPrecio;
    }

    public void setPresentacionPrecio(BigDecimal presentacionPrecio) {
        this.presentacionPrecio = presentacionPrecio;
    }

    public String getVentaUnidadNombre() {
        return ventaUnidadNombre;
    }

    public void setVentaUnidadNombre(String ventaUnidadNombre) {
        this.ventaUnidadNombre = ventaUnidadNombre;
    }

    public BigDecimal getVentaUnidadContenido() {
        return ventaUnidadContenido;
    }

    public void setVentaUnidadContenido(BigDecimal ventaUnidadContenido) {
        this.ventaUnidadContenido = ventaUnidadContenido;
    }

    public TipoArticulo getTipo() {
        return tipo;
    }

    public void setTipo(TipoArticulo tipo) {
        this.tipo = tipo;
    }

    public boolean isVendible() {
        return vendible;
    }

    public void setVendible(boolean vendible) {
        this.vendible = vendible;
    }

    public Long getVersion() {
        return version;
    }

    /** Se muestra y se puede vender en el POS. */
    public boolean esVendibleEnPos() {
        return activo && tipo.seVende() && vendible;
    }

    /** ELABORADO que no se vende (ej. ganache): "Preparación base". */
    public boolean esPreparacionBase() {
        return tipo == TipoArticulo.ELABORADO && !vendible;
    }

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