package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.entities.*;
import com.sgiu_group.sgiu.exceptions.InsumoInsuficienteException;
import com.sgiu_group.sgiu.exceptions.ProductoNoEncontradoException;
import com.sgiu_group.sgiu.exceptions.StockInsuficienteException;
import com.sgiu_group.sgiu.repositories.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
public class VentaService {

    // Definimos las dependencias como final (inmutables)
    private final VentaRepository ventaRepository;
    private final ArticuloStockRepository stockRepository;
    private final PagoVentaRepository pagoRepository;
    private final MovFinancieroRepository movFinancieroRepository;
    private final RecetaRepository recetaRepository;
    private final MateriaPrimaRepository materiaPrimaRepository;

    // Inyección por constructor: No requiere @Autowired manual
    public VentaService(VentaRepository ventaRepository, 
                        ArticuloStockRepository stockRepository,
                        PagoVentaRepository pagoRepository,
                        MovFinancieroRepository movFinancieroRepository,
                        RecetaRepository recetaRepository,
                        MateriaPrimaRepository materiaPrimaRepository) {
        this.ventaRepository = ventaRepository;
        this.stockRepository = stockRepository;
        this.pagoRepository = pagoRepository;
        this.movFinancieroRepository = movFinancieroRepository;
        this.recetaRepository = recetaRepository;
        this.materiaPrimaRepository = materiaPrimaRepository;
    }

    @Transactional
    public void procesarVenta(VentaRequestDTO request) {
        Venta venta = new Venta();
        // Setear valores requeridos por PR #13 para evitar errores de nulidad
        venta.setIdSesionCaja(0); // Valor por defecto temporal
        venta.setCreadoPorUsuario(0); // Valor por defecto temporal
        BigDecimal totalAcumulado = BigDecimal.ZERO;

        // Fase 1: Validación y acumulación de demanda de insumos para productos con receta (elaborados)
        Map<MateriaPrima, Integer> insumosDemandados = new HashMap<>();
        Map<String, ArticuloStock> stockPorCodigo = new HashMap<>();

        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockRepository.findByEspProducto_Codigo(dto.codigoProducto())
                .orElseThrow(() -> new ProductoNoEncontradoException("Producto no encontrado: " + dto.codigoProducto()));
            stockPorCodigo.put(dto.codigoProducto(), stock);

            // RN02: Verificación de stock de producto final
            if (stock.getCantidad() < dto.cantidad()) {
                throw new StockInsuficienteException("Stock insuficiente para: " + dto.codigoProducto());
            }

            // Verificación de materias primas si el producto tiene receta
            Optional<Receta> recetaOpt = recetaRepository.findByProducto_IdAndActivoTrue(stock.getEspProducto().getId());
            if (recetaOpt.isPresent()) {
                for (RecetaDetalle detalle : recetaOpt.get().getDetalles()) {
                    MateriaPrima mp = detalle.getMateriaPrima();
                    BigDecimal requerida = detalle.getCantidad().multiply(BigDecimal.valueOf(dto.cantidad()));
                    int requeridaInt = (int) Math.ceil(requerida.doubleValue());
                    insumosDemandados.merge(mp, requeridaInt, Integer::sum);
                }
            }
        }

        // Validación de existencia de materias primas requeridas
        for (Map.Entry<MateriaPrima, Integer> entry : insumosDemandados.entrySet()) {
            MateriaPrima mp = entry.getKey();
            int totalRequerido = entry.getValue();
            if (mp.getStockActual() < totalRequerido) {
                throw new InsumoInsuficienteException("Stock insuficiente de materia prima: " + mp.getNombre() +
                        " (requerido: " + totalRequerido + ", disponible: " + mp.getStockActual() + ")");
            }
        }

        // Fase 2: Descuento de materias primas
        for (Map.Entry<MateriaPrima, Integer> entry : insumosDemandados.entrySet()) {
            MateriaPrima mp = entry.getKey();
            mp.setStockActual(mp.getStockActual() - entry.getValue());
            materiaPrimaRepository.save(mp);
        }

        // Fase 3: Descuento de stock de productos y armado de líneas de venta
        for (LineaVentaDTO dto : request.lineas()) {
            ArticuloStock stock = stockPorCodigo.get(dto.codigoProducto());

            // Descuento de inventario
            stock.setCantidad(stock.getCantidad() - dto.cantidad());
            stockRepository.save(stock);

            // Obtenemos precio unitario real de la BD (RN05)
            BigDecimal precioUnitario = stock.getEspProducto().getPrecioUnitario();
            
            // Creamos la línea de venta
            LineaVenta linea = new LineaVenta(venta, stock.getEspProducto(), dto.cantidad());
            venta.addLinea(linea);

            // Calculamos subtotal
            totalAcumulado = totalAcumulado.add(precioUnitario.multiply(new BigDecimal(dto.cantidad())));
        }

        venta.setTotal(totalAcumulado);
        Venta ventaGuardada = ventaRepository.save(venta);

        // Registro de Pago
        String metodoPagoStr = request.metodoPago() != null ? request.metodoPago().toString() : "EFECTIVO";
        PagoVenta pago = new PagoVenta(ventaGuardada, totalAcumulado, metodoPagoStr);
        pagoRepository.save(pago);

        // Registro Financiero (Ingreso)
        MovFinanciero movimiento = new MovFinanciero(
            TipoMovimiento.INGRESO,
            totalAcumulado,
            metodoPagoStr,
            "VENTA",
            "Venta de productos - ID: " + ventaGuardada.getId(),
            ventaGuardada.getFechaHora(),
            pago
        );
        movFinancieroRepository.save(movimiento);
    }
}