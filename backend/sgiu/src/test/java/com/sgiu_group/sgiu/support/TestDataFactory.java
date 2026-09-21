package com.sgiu_group.sgiu.support;

import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.models.entities.LineaVenta;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
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

    public TestDataFactory(EspProductoRepository productoRepository,
                           ArticuloStockRepository stockRepository,
                           VentaRepository ventaRepository,
                           PagoVentaRepository pagoRepository,
                           MovFinancieroRepository movFinancieroRepository,
                           EspUsuarioRepository usuarioRepository,
                           PasswordEncoder passwordEncoder) {
        this.productoRepository = productoRepository;
        this.stockRepository = stockRepository;
        this.ventaRepository = ventaRepository;
        this.pagoRepository = pagoRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public static String codigoUnico(String prefijo) {
        return prefijo + "-" + COUNTER.incrementAndGet();
    }

    public EspProducto crearProducto(String codigo, String nombre, BigDecimal precio,
                                     int cantidadStock, int stockMinimo) {
        EspProducto producto = new EspProducto(codigo, nombre, precio);
        productoRepository.save(producto);

        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(cantidadStock);
        stock.setStockMinimo(stockMinimo);
        stockRepository.save(stock);
        return producto;
    }

    public MovFinanciero crearMovimiento(TipoMovimiento tipo, BigDecimal monto, String metodoPago,
                                         String categoria, LocalDateTime fechaHora) {
        MovFinanciero mov = new MovFinanciero(
                tipo, monto, metodoPago, categoria, "Movimiento de test", fechaHora, null);
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

        PagoVenta pago = new PagoVenta(venta, venta.getTotal(), metodoPago);
        pagoRepository.save(pago);

        movFinancieroRepository.save(new MovFinanciero(
                TipoMovimiento.INGRESO,
                venta.getTotal(),
                metodoPago,
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