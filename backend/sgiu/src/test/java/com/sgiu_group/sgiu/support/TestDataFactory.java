package com.sgiu_group.sgiu.support;

import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.models.entities.LineaVenta;
import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import com.sgiu_group.sgiu.services.CostosService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicInteger;

@Component
public class TestDataFactory {

    private static final AtomicInteger COUNTER = new AtomicInteger(0);

    private final EspProductoRepository productoRepository;
    private final ArticuloStockRepository stockRepository;
    private final VentaRepository ventaRepository;
    private final PagoVentaRepository pagoRepository;
    private final MovFinancieroRepository movFinancieroRepository;
    private final EspUsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final MetodoPagoRepository metodoPagoRepository;
    private final CostosService costosService;

    public TestDataFactory(EspProductoRepository productoRepository,
                           ArticuloStockRepository stockRepository,
                           VentaRepository ventaRepository,
                           PagoVentaRepository pagoRepository,
                           MovFinancieroRepository movFinancieroRepository,
                           EspUsuarioRepository usuarioRepository,
                           PasswordEncoder passwordEncoder,
                           MetodoPagoRepository metodoPagoRepository,
                           CostosService costosService) {
        this.productoRepository = productoRepository;
        this.stockRepository = stockRepository;
        this.ventaRepository = ventaRepository;
        this.pagoRepository = pagoRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.metodoPagoRepository = metodoPagoRepository;
        this.costosService = costosService;
    }

    /** Método de pago por nombre ("EFECTIVO", "MERCADO_PAGO" o "Mercado Pago"). */
    public MetodoPago metodo(String nombre) {
        return metodoPagoRepository.findByNombreIgnoreCase(nombre.replace('_', ' '))
                .orElseThrow(() -> new IllegalArgumentException("No existe el método de pago " + nombre));
    }

    public static String codigoUnico(String prefijo) {
        return prefijo + "-" + COUNTER.incrementAndGet();
    }

    public EspProducto crearProducto(String codigo, String nombre, BigDecimal precio,
                                     int cantidadStock, int stockMinimo) {
        EspProducto producto = new EspProducto(codigo, nombre, precio);
        productoRepository.save(producto);

        ArticuloStock stock = new ArticuloStock(producto, cantidadStock);
        stock.setStockMinimo(BigDecimal.valueOf(stockMinimo));
        stockRepository.save(stock);
        return producto;
    }

    /**
     * Materia prima con costo, stock y stock mínimo expresados en [unidad]
     * (p. ej. $1000 el kilo y 10 kilos): se guardan en unidad base (1 por
     * gramo, 10000 g). La presentación de compra es 1 [unidad] a ese costo.
     */
    public EspProducto crearMateriaPrima(String codigo, String nombre, BigDecimal costoPorUnidad,
                                         UnidadMedida unidad, int stock, int stockMinimo) {
        return crearArticuloDeMateriaPrima(TipoArticulo.MATERIA_PRIMA, codigo, nombre, costoPorUnidad, unidad,
                stock, stockMinimo);
    }

    public EspProducto crearArticuloDeMateriaPrima(TipoArticulo tipo, String codigo, String nombre,
                                                   BigDecimal costoPorUnidad, UnidadMedida unidad,
                                                   int stock, int stockMinimo) {
        EspProducto articulo = new EspProducto(codigo, nombre, BigDecimal.ZERO);
        articulo.setTipo(tipo);
        articulo.setFamilia(unidad.getFamilia());
        articulo.setUnidadMedida(unidad);
        articulo.setCostoUnidadBase(costoPorUnidad.divide(unidad.getFactor(), 4, RoundingMode.HALF_UP));
        articulo.setPresentacionCantidad(BigDecimal.ONE);
        articulo.setPresentacionUnidad(unidad);
        articulo.setPresentacionPrecio(costoPorUnidad);
        productoRepository.save(articulo);

        ArticuloStock articuloStock = new ArticuloStock(articulo, unidad.aBase(BigDecimal.valueOf(stock)));
        articuloStock.setStockMinimo(unidad.aBase(BigDecimal.valueOf(stockMinimo)));
        stockRepository.save(articuloStock);
        return articulo;
    }

    /**
     * Reventa + materia prima por peso: se compra [presentacionGramos] a
     * [precioPresentacion] y se vende por [ventaUnidad] de [contenidoGramos],
     * con [porcentaje] de ganancia. Stock en gramos.
     */
    public EspProducto crearReventaMateriaPrima(String codigo, String nombre, int presentacionGramos,
                                                BigDecimal precioPresentacion, String ventaUnidad,
                                                int contenidoGramos, BigDecimal porcentaje, int stockGramos) {
        EspProducto articulo = new EspProducto(codigo, nombre, BigDecimal.ZERO);
        articulo.setTipo(TipoArticulo.REVENTA_MATERIA_PRIMA);
        articulo.setFamilia(UnidadMedida.GRAMO.getFamilia());
        articulo.setUnidadMedida(UnidadMedida.GRAMO);
        articulo.setPresentacionCantidad(BigDecimal.valueOf(presentacionGramos));
        articulo.setPresentacionUnidad(UnidadMedida.GRAMO);
        articulo.setPresentacionPrecio(precioPresentacion);
        articulo.setCostoUnidadBase(precioPresentacion.divide(BigDecimal.valueOf(presentacionGramos), 4, RoundingMode.HALF_UP));
        articulo.setVentaUnidadNombre(ventaUnidad);
        articulo.setVentaUnidadContenido(BigDecimal.valueOf(contenidoGramos).setScale(3));
        articulo.setPorcentajeGanancia(porcentaje);
        costosService.recalcular(articulo);
        productoRepository.save(articulo);
        // Con 3 decimales, como en la base.
        stockRepository.save(new ArticuloStock(articulo, BigDecimal.valueOf(stockGramos).setScale(3)));
        return articulo;
    }

    /** Producto ELABORADO (vendible = false: preparación base). */
    public EspProducto crearElaborado(String codigo, String nombre, BigDecimal precio,
                                      int cantidadStock, boolean vendible) {
        EspProducto producto = crearProducto(codigo, nombre, precio, cantidadStock, 0);
        producto.setTipo(com.sgiu_group.sgiu.models.entities.TipoArticulo.ELABORADO);
        producto.setVendible(vendible);
        return productoRepository.save(producto);
    }

    public MovFinanciero crearMovimiento(TipoMovimiento tipo, BigDecimal monto, String metodoPago,
                                         String categoria, LocalDateTime fechaHora) {
        MovFinanciero mov = new MovFinanciero(
                tipo, monto, metodo(metodoPago), categoria, "Movimiento de test", fechaHora, null);
        return movFinancieroRepository.save(mov);
    }

    public Venta crearVenta(EspProducto producto, int cantidad, String metodoPago,
                            LocalDateTime fechaHora) {
        Venta venta = new Venta();
        venta.setFechaHora(fechaHora);
        venta.setIdSesionCaja(0);
        venta.setCreadoPorUsuario(0);

        LineaVenta linea = new LineaVenta(venta, producto, cantidad);
        venta.addLinea(linea);
        venta.setTotal(linea.getSubtotal());
        ventaRepository.save(venta);

        PagoVenta pago = new PagoVenta(venta, venta.getTotal(), metodo(metodoPago));
        pagoRepository.save(pago);

        movFinancieroRepository.save(new MovFinanciero(
                TipoMovimiento.INGRESO,
                venta.getTotal(),
                pago.getMetodoPago(),
                "VENTA",
                "Venta de test - " + producto.getCodigo(),
                fechaHora,
                pago));
        return venta;
    }

    public EspUsuario crearUsuario(String username, String password, boolean activo) {
        EspUsuario usuario = new EspUsuario(username, passwordEncoder.encode(password), activo);
        return usuarioRepository.save(usuario);
    }
}