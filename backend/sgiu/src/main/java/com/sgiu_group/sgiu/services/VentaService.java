package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.dtos.PagoVentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.VentaResponseDTO;
import com.sgiu_group.sgiu.exceptions.PagoInvalidoException;
import com.sgiu_group.sgiu.exceptions.PrecioInvalidoException;
import com.sgiu_group.sgiu.models.entities.*;
import com.sgiu_group.sgiu.exceptions.ProductoInvalidoException;
import com.sgiu_group.sgiu.exceptions.ProductoNoEncontradoException;
import com.sgiu_group.sgiu.exceptions.StockInsuficienteException;
import com.sgiu_group.sgiu.repositories.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class VentaService {

    // Definimos las dependencias como final (inmutables)
    private final VentaRepository ventaRepository;
    private final ArticuloStockRepository stockRepository;
    private final PagoVentaRepository pagoRepository;
    private final MovFinancieroRepository movFinancieroRepository;
    private final MetodoPagoService metodoPagoService;
    private final HistorialPrecioRepository historialPrecioRepository;

    /** Cuánto dura congelado el precio de un carrito después de un cambio de precio. */
    private static final long HORAS_PRECIO_CONGELADO = 24;

    // Inyección por constructor: No requiere @Autowired manual
    public VentaService(VentaRepository ventaRepository,
                        ArticuloStockRepository stockRepository,
                        PagoVentaRepository pagoRepository,
                        MovFinancieroRepository movFinancieroRepository,
                        MetodoPagoService metodoPagoService,
                        HistorialPrecioRepository historialPrecioRepository) {
        this.ventaRepository = ventaRepository;
        this.stockRepository = stockRepository;
        this.pagoRepository = pagoRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.metodoPagoService = metodoPagoService;
        this.historialPrecioRepository = historialPrecioRepository;
    }

    /**
     * Sandra produce por tanda: la venta verifica y descuenta solo el stock
     * del producto final. Los insumos se descuentan al producir, no al vender,
     * así que la receta no interviene acá.
     */
    @Transactional
    public VentaResponseDTO procesarVenta(VentaRequestDTO request) {
        Venta venta = new Venta();
        // Setear valores requeridos por PR #13 para evitar errores de nulidad
        venta.setIdSesionCaja(0); // Valor por defecto temporal
        venta.setCreadoPorUsuario(0); // Valor por defecto temporal
        BigDecimal totalAcumulado = BigDecimal.ZERO;

        // Fase 1: validación de stock y total de todas las líneas antes de tocar nada
        Map<String, ArticuloStock> stockPorCodigo = new HashMap<>();
        Map<LineaVentaDTO, BigDecimal> precioPorLinea = new HashMap<>();
        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockRepository.findByEspProducto_Codigo(dto.codigoProducto())
                .orElseThrow(() -> new ProductoNoEncontradoException("Producto no encontrado: " + dto.codigoProducto()));
            stockPorCodigo.put(dto.codigoProducto(), stock);
            validarVendible(stock.getEspProducto());

            // RN02: Verificación de stock de producto final. La reventa +
            // materia prima se vende por unidades enteras (1 caja = 100 g):
            // lo suelto nunca se vende.
            EspProducto producto = stock.getEspProducto();
            if (producto.stockParaVender(dto.cantidad()).compareTo(stock.getCantidad()) > 0) {
                throw new StockInsuficienteException("Stock insuficiente para "
                        + producto.getNombre() + " (código " + dto.codigoProducto()
                        + "): disponible " + producto.unidadesDeVentaEn(stock.getCantidad())
                        + ", solicitado " + dto.cantidad() + ".");
            }
            // Precio de la BD (RN05), salvo el congelado en el carrito.
            BigDecimal precio = precioDeLaLinea(producto, dto);
            precioPorLinea.put(dto, precio);
            totalAcumulado = totalAcumulado.add(precio.multiply(new BigDecimal(dto.cantidad())));
        }

        // Los pagos se validan antes de tocar el stock: si no cubren el
        // total, no se modifica nada.
        Cobro cobro = armarCobro(request, totalAcumulado);

        // Fase 2: descuento de stock de productos y armado de líneas de venta
        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockPorCodigo.get(dto.codigoProducto());

            // Descuento de inventario (en unidad base: 1 caja = 100 g)
            stock.setCantidad(stock.getCantidad().subtract(stock.getEspProducto().stockParaVender(dto.cantidad())));
            stockRepository.save(stock);

            // Creamos la línea de venta
            LineaVenta linea = new LineaVenta(venta, stock.getEspProducto(), dto.cantidad());
            linea.setPrecioUnitario(precioPorLinea.get(dto));
            venta.addLinea(linea);
        }

        venta.setTotal(totalAcumulado);
        Venta ventaGuardada = ventaRepository.save(venta);

        // Una fila de pago y un movimiento por línea, así el balance y el
        // dashboard se pueden desglosar por método.
        List<VentaResponseDTO.PagoRegistradoDTO> registrados = new ArrayList<>();
        for (Map.Entry<MetodoPago, BigDecimal> linea : cobro.montos().entrySet()) {
            PagoVenta pago = pagoRepository.save(new PagoVenta(ventaGuardada, linea.getValue(), linea.getKey()));
            movFinancieroRepository.save(new MovFinanciero(
                    TipoMovimiento.INGRESO,
                    linea.getValue(),
                    linea.getKey(),
                    "VENTA",
                    "Venta de productos - ID: " + ventaGuardada.getId(),
                    ventaGuardada.getFechaHora(),
                    pago));
            registrados.add(new VentaResponseDTO.PagoRegistradoDTO(
                    linea.getKey().getId(), linea.getKey().getNombre(), linea.getValue()));
        }
        return new VentaResponseDTO(ventaGuardada.getId(), totalAcumulado, cobro.vuelto(), registrados);
    }

    /**
     * Precio que se cobra: el actual o, si el carrito trae otro, ese mismo
     * siempre que el producto lo haya tenido hasta un cambio de las últimas
     * 24 horas (el precio del carrito queda congelado). Si no, se rechaza.
     */
    private BigDecimal precioDeLaLinea(EspProducto producto, LineaVentaDTO dto) {
        BigDecimal actual = producto.getPrecioUnitario();
        if (dto.precioUnitario() == null || dto.precioUnitario().compareTo(actual) == 0) {
            return actual;
        }
        boolean congelado = historialPrecioRepository.tuvoPrecioDesde(producto.getId(), dto.precioUnitario(),
                LocalDateTime.now().minusHours(HORAS_PRECIO_CONGELADO));
        if (!congelado) {
            throw new PrecioInvalidoException("El precio de " + producto.getNombre() + " es $"
                    + actual.toPlainString() + ", no $" + dto.precioUnitario().toPlainString()
                    + ". Quítelo del carrito y vuelva a agregarlo.");
        }
        return dto.precioUnitario().setScale(2, RoundingMode.HALF_UP);
    }

    /** Lo que se registra por método (en orden) y el vuelto en efectivo. */
    private record Cobro(Map<MetodoPago, BigDecimal> montos, BigDecimal vuelto) {}

    /**
     * Pago mixto (D.4.1/D.4.2): las líneas tienen que cubrir el total; solo
     * el efectivo puede pasarse (la diferencia es el vuelto y se registra lo
     * que corresponde a la venta). Sin líneas, se cobra todo con un método.
     */
    private Cobro armarCobro(VentaRequestDTO request, BigDecimal total) {
        Map<MetodoPago, BigDecimal> montos = new LinkedHashMap<>();
        if (request.pagos() == null || request.pagos().isEmpty()) {
            MetodoPago metodo = request.metodoPago() != null
                    ? metodoPagoService.paraCobrar(request.metodoPago())
                    : metodoPagoService.efectivo();
            montos.put(metodo, total);
            return new Cobro(montos, BigDecimal.ZERO);
        }

        BigDecimal pagado = BigDecimal.ZERO;
        BigDecimal noEfectivo = BigDecimal.ZERO;
        Set<Long> vistos = new HashSet<>();
        for (PagoVentaRequestDTO linea : request.pagos()) {
            MetodoPago metodo = metodoPagoService.paraCobrar(linea.metodoPagoId());
            if (!vistos.add(metodo.getId())) {
                throw new PagoInvalidoException("El método " + metodo.getNombre()
                        + " está dos veces; sume los montos en una sola línea.");
            }
            BigDecimal monto = linea.monto().setScale(2, RoundingMode.HALF_UP);
            montos.put(metodo, monto);
            pagado = pagado.add(monto);
            if (!metodo.esEfectivo()) {
                noEfectivo = noEfectivo.add(monto);
            }
        }
        if (noEfectivo.compareTo(total) > 0) {
            throw new PagoInvalidoException("Los pagos que no son en efectivo ($" + noEfectivo
                    + ") superan el total de la venta ($" + total + "). Solo el efectivo puede tener vuelto.");
        }
        if (pagado.compareTo(total) < 0) {
            throw new PagoInvalidoException("Los pagos ($" + pagado + ") no cubren el total de la venta ($"
                    + total + "). Falta $" + total.subtract(pagado) + ".");
        }

        // El vuelto sale del efectivo: se registra solo lo que corresponde a
        // la venta (y si el efectivo era todo vuelto, no se registra).
        BigDecimal vuelto = pagado.subtract(total);
        if (vuelto.signum() > 0) {
            MetodoPago efectivo = montos.keySet().stream().filter(MetodoPago::esEfectivo).findFirst().orElseThrow();
            BigDecimal registrado = montos.get(efectivo).subtract(vuelto);
            if (registrado.signum() > 0) {
                montos.put(efectivo, registrado);
            } else {
                montos.remove(efectivo);
            }
        }
        return new Cobro(montos, vuelto);
    }

    /** Solo se vende lo que el POS muestra (ver EspProducto.esVendibleEnPos). */
    private static void validarVendible(EspProducto producto) {
        if (producto.esVendibleEnPos()) {
            return;
        }
        if (!producto.isActivo()) {
            throw new ProductoInvalidoException(producto.getNombre() + " está desactivado y no se puede vender.");
        }
        if (producto.esPreparacionBase()) {
            throw new ProductoInvalidoException(producto.getNombre() + " es una preparación base y no se vende.");
        }
        throw new ProductoInvalidoException(producto.getNombre() + " no se vende en el punto de venta.");
    }
}
