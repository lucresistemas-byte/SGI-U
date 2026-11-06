package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.dtos.PagoVentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.VentaResponseDTO;
import com.sgiu_group.sgiu.models.dtos.VentaResumenDTO;
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
import java.time.LocalDate;
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

    private final VentaRepository ventaRepository;
    private final ArticuloStockRepository stockRepository;
    private final PagoVentaRepository pagoRepository;
    private final MovFinancieroRepository movFinancieroRepository;
    private final MetodoPagoService metodoPagoService;
    private final HistorialPrecioRepository historialPrecioRepository;
    private final StockService stockService;

    /** Cuánto dura congelado el precio de un carrito después de un cambio de precio. */
    private static final long HORAS_PRECIO_CONGELADO = 24;

    public VentaService(VentaRepository ventaRepository,
                        ArticuloStockRepository stockRepository,
                        PagoVentaRepository pagoRepository,
                        MovFinancieroRepository movFinancieroRepository,
                        MetodoPagoService metodoPagoService,
                        HistorialPrecioRepository historialPrecioRepository,
                        StockService stockService) {
        this.ventaRepository = ventaRepository;
        this.stockRepository = stockRepository;
        this.pagoRepository = pagoRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.metodoPagoService = metodoPagoService;
        this.historialPrecioRepository = historialPrecioRepository;
        this.stockService = stockService;
    }

    /**
     * Sandra produce por tanda: la venta verifica y descuenta solo el stock
     * del producto final. Los insumos se descuentan al producir, no al vender.
     */
    @Transactional
    public VentaResponseDTO procesarVenta(VentaRequestDTO request) {
        // A2: idempotencia. Si este token ya registró una venta, se devuelve la existente
        String token = request.tokenIdempotencia() != null && !request.tokenIdempotencia().isBlank()
                ? request.tokenIdempotencia().trim()
                : null;
        if (token != null) {
            var existente = ventaRepository.findByTokenIdempotencia(token);
            if (existente.isPresent()) {
                return respuestaDeVentaExistente(existente.get());
            }
        }

        Venta venta = new Venta();
        venta.setTokenIdempotencia(token);
        venta.setIdSesionCaja(0);
        venta.setCreadoPorUsuario(0);
        BigDecimal totalAcumulado = BigDecimal.ZERO;

        // Fase 1: acumular cantidades por código de producto (R-14)
        Map<String, Integer> cantidadesPorCodigo = new LinkedHashMap<>();
        for (LineaVentaDTO dto : request.lineas()) {
            cantidadesPorCodigo.merge(dto.codigoProducto(), dto.cantidad(), Integer::sum);
        }

        Map<String, ArticuloStock> stockPorCodigo = new HashMap<>();
        // Validar stock total acumulado de cada producto antes de cobrar (R-14)
        for (Map.Entry<String, Integer> entry : cantidadesPorCodigo.entrySet()) {
            String codigo = entry.getKey();
            int cantidadTotalRequerida = entry.getValue();

            ArticuloStock stock = stockRepository.findByEspProducto_Codigo(codigo)
                    .orElseThrow(() -> new ProductoNoEncontradoException("Producto no encontrado: " + codigo));
            stockPorCodigo.put(codigo, stock);
            validarVendible(stock.getEspProducto());

            EspProducto producto = stock.getEspProducto();
            BigDecimal stockDisponible = stock.getCantidad();
            BigDecimal necesarioEnUnidadBase = producto.stockParaVender(cantidadTotalRequerida);

            if (necesarioEnUnidadBase.compareTo(stockDisponible) > 0) {
                throw new StockInsuficienteException("Stock insuficiente para "
                        + producto.getNombre() + " (código " + codigo
                        + "): disponible " + producto.unidadesDeVentaEn(stockDisponible)
                        + ", solicitado " + cantidadTotalRequerida + ".");
            }
        }

        // Validar precios de cada línea y sumar total
        Map<LineaVentaDTO, BigDecimal> precioPorLinea = new HashMap<>();
        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockPorCodigo.get(dto.codigoProducto());
            BigDecimal precio = precioDeLaLinea(stock.getEspProducto(), dto);
            precioPorLinea.put(dto, precio);
            totalAcumulado = totalAcumulado.add(precio.multiply(new BigDecimal(dto.cantidad())));
        }

        // Los pagos se validan antes de tocar el stock
        Cobro cobro = armarCobro(request, totalAcumulado);

        // Fase 2: armado de líneas de venta
        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockPorCodigo.get(dto.codigoProducto());
            LineaVenta linea = new LineaVenta(venta, stock.getEspProducto(), dto.cantidad());
            linea.setPrecioUnitario(precioPorLinea.get(dto));
            venta.addLinea(linea);
        }

        venta.setTotal(totalAcumulado);
        Venta ventaGuardada = ventaRepository.save(venta);

        // Descuento de inventario en unidad base
        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockPorCodigo.get(dto.codigoProducto());
            EspProducto producto = stock.getEspProducto();
            stockService.mover(stock, TipoMovimientoStock.VENTA, producto.stockParaVender(dto.cantidad()).negate(),
                    "Venta #" + ventaGuardada.getId(), null, ventaGuardada);
        }

        // Registro de pagos y movimientos financieros
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
     * R-15: Anulación total de venta.
     * Revierte el stock (TipoMovimientoStock.ANULACION_VENTA), revierte los movimientos
     * financieros de caja (EGRESO por anulación) y marca la venta como anulada.
     */
    @Transactional
    public VentaResumenDTO anularVenta(Long ventaId, String motivo, String username) {
        Venta venta = ventaRepository.findById(ventaId)
                .orElseThrow(() -> new IllegalArgumentException("Venta no encontrada con ID: " + ventaId));

        if (Boolean.TRUE.equals(venta.getAnulada())) {
            throw new IllegalStateException("La venta #" + ventaId + " ya fue anulada previamente el "
                    + venta.getFechaHoraAnulacion() + " (Motivo: " + venta.getMotivoAnulacion() + ").");
        }

        String motivoFinal = (motivo != null && !motivo.isBlank()) ? motivo.trim() : "Anulación de venta #" + ventaId;
        String usuarioFinal = (username != null && !username.isBlank()) ? username.trim() : "ADMIN";
        LocalDateTime ahora = LocalDateTime.now();

        // 1. Revertir inventario: devolver al stock la cantidad de cada línea
        for (LineaVenta linea : venta.getLineas()) {
            EspProducto producto = linea.getProducto();
            ArticuloStock stock = stockRepository.findByEspProducto_Codigo(producto.getCodigo())
                    .orElseThrow(() -> new IllegalStateException("Stock no encontrado para producto: " + producto.getCodigo()));

            BigDecimal cantidadBaseDevuelta = producto.stockParaVender(linea.getCantidad());
            stockService.mover(stock, TipoMovimientoStock.ANULACION_VENTA, cantidadBaseDevuelta,
                    "Anulación Venta #" + ventaId + ": " + motivoFinal, null, venta);
        }

        // 2. Revertir movimientos financieros: generar EGRESO compensatorio por cada pago original
        List<PagoVenta> pagos = pagoRepository.findByVentaId(ventaId);
        for (PagoVenta pago : pagos) {
            movFinancieroRepository.save(new MovFinanciero(
                    TipoMovimiento.EGRESO,
                    pago.getMonto(),
                    pago.getMetodoPago(),
                    "OTRO", // categoría general de egreso
                    "Anulación de cobro - Venta #" + ventaId + " (" + motivoFinal + ")",
                    ahora,
                    null));
        }

        // 3. Marcar la venta como anulada
        venta.setAnulada(true);
        venta.setMotivoAnulacion(motivoFinal);
        venta.setFechaHoraAnulacion(ahora);
        venta.setAnuladoPorUsuario(usuarioFinal);
        Venta guardada = ventaRepository.save(venta);

        return mapearAResumen(guardada, pagos);
    }

    /**
     * R-15: Listar ventas filtradas por fecha (por defecto: hoy).
     */
    @Transactional(readOnly = true)
    public List<VentaResumenDTO> listarVentasPorFecha(LocalDate desde, LocalDate hasta) {
        LocalDate fechaInicio = (desde != null) ? desde : LocalDate.now();
        LocalDate fechaFin = (hasta != null) ? hasta : fechaInicio.plusDays(1);

        LocalDateTime inicio = fechaInicio.atStartOfDay();
        LocalDateTime fin = fechaFin.atStartOfDay();

        List<Venta> ventas = ventaRepository.findByFechaHoraGreaterThanEqualAndFechaHoraLessThanOrderByFechaHoraDesc(inicio, fin);
        List<VentaResumenDTO> res = new ArrayList<>();
        for (Venta v : ventas) {
            List<PagoVenta> pagos = pagoRepository.findByVentaId(v.getId());
            res.add(mapearAResumen(v, pagos));
        }
        return res;
    }

    private VentaResumenDTO mapearAResumen(Venta v, List<PagoVenta> pagos) {
        List<VentaResumenDTO.LineaResumenDTO> lineasDTO = new ArrayList<>();
        if (v.getLineas() != null) {
            for (LineaVenta lv : v.getLineas()) {
                BigDecimal subtotal = (lv.getPrecioUnitario() != null && lv.getCantidad() != null)
                        ? lv.getPrecioUnitario().multiply(BigDecimal.valueOf(lv.getCantidad()))
                        : BigDecimal.ZERO;
                lineasDTO.add(new VentaResumenDTO.LineaResumenDTO(
                        lv.getProducto() != null ? lv.getProducto().getCodigo() : "N/A",
                        lv.getProducto() != null ? lv.getProducto().getNombre() : "N/A",
                        lv.getCantidad(),
                        lv.getPrecioUnitario(),
                        subtotal));
            }
        }
        List<VentaResumenDTO.PagoResumenDTO> pagosDTO = new ArrayList<>();
        if (pagos != null) {
            for (PagoVenta pv : pagos) {
                pagosDTO.add(new VentaResumenDTO.PagoResumenDTO(
                        pv.getMetodoPago().getId(),
                        pv.getMetodoPago().getNombre(),
                        pv.getMonto()));
            }
        }
        return new VentaResumenDTO(
                v.getId(),
                v.getFechaHora(),
                v.getTotal(),
                v.getAnulada(),
                v.getMotivoAnulacion(),
                v.getFechaHoraAnulacion(),
                v.getAnuladoPorUsuario(),
                lineasDTO,
                pagosDTO);
    }

    private VentaResponseDTO respuestaDeVentaExistente(Venta v) {
        List<PagoVenta> pagos = pagoRepository.findByVentaId(v.getId());
        List<VentaResponseDTO.PagoRegistradoDTO> registrados = new ArrayList<>();
        for (PagoVenta p : pagos) {
            registrados.add(new VentaResponseDTO.PagoRegistradoDTO(
                    p.getMetodoPago().getId(),
                    p.getMetodoPago().getNombre(),
                    p.getMonto()));
        }
        return new VentaResponseDTO(v.getId(), v.getTotal(), BigDecimal.ZERO, registrados);
    }

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

    private record Cobro(Map<MetodoPago, BigDecimal> montos, BigDecimal vuelto) {}

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
