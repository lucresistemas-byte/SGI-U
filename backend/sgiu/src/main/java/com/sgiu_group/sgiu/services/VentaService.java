package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.entities.*;
import com.sgiu_group.sgiu.exceptions.ProductoNoEncontradoException;
import com.sgiu_group.sgiu.exceptions.StockInsuficienteException;
import com.sgiu_group.sgiu.repositories.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
public class VentaService {

    // Definimos las dependencias como final (inmutables)
    private final VentaRepository ventaRepository;
    private final ArticuloStockRepository stockRepository;
    private final PagoVentaRepository pagoRepository;
    private final MovFinancieroRepository movFinancieroRepository;

    // Inyección por constructor: No requiere @Autowired manual
    public VentaService(VentaRepository ventaRepository, 
                        ArticuloStockRepository stockRepository,
                        PagoVentaRepository pagoRepository,
                        MovFinancieroRepository movFinancieroRepository) {
        this.ventaRepository = ventaRepository;
        this.stockRepository = stockRepository;
        this.pagoRepository = pagoRepository;
        this.movFinancieroRepository = movFinancieroRepository;
    }

    @Transactional
    public void procesarVenta(VentaRequestDTO request) {
        Venta venta = new Venta();
        // Setear valores requeridos por PR #13 para evitar errores de nulidad
        venta.setIdSesionCaja(0); // Valor por defecto temporal
        venta.setCreadoPorUsuario(0); // Valor por defecto temporal
        BigDecimal totalAcumulado = BigDecimal.ZERO;

        for (LineaVentaDTO dto : request.lineas()) {
            // Buscamos el stock directamente por el código del producto (RN05)
            ArticuloStock stock = stockRepository.findByEspProducto_Codigo(dto.codigoProducto())
                .orElseThrow(() -> new ProductoNoEncontradoException("Producto no encontrado: " + dto.codigoProducto()));

            // RN02: Verificación de stock insuficiente
            if (stock.getCantidad() < dto.cantidad()) {
                throw new StockInsuficienteException("Stock insuficiente para: " + dto.codigoProducto());
            }

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