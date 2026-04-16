package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.entities.*;
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
        BigDecimal totalAcumulado = BigDecimal.ZERO;

        for (LineaVentaDTO dto : request.lineas()) {
            // Buscamos el stock directamente por el código del producto (RN05)
            ArticuloStock stock = stockRepository.findByEspProducto_Codigo(dto.codigoProducto())
                .orElseThrow(() -> new RuntimeException("Producto no encontrado: " + dto.codigoProducto()));

            // RN02: Verificación de stock insuficiente
            if (stock.getCantidad() < dto.cantidad()) {
                throw new RuntimeException("Stock insuficiente para: " + dto.codigoProducto());
            }

            // Descuento de inventario
            stock.setCantidad(stock.getCantidad() - dto.cantidad());
            stockRepository.save(stock);

            // Obtenemos precio unitario real de la BD (RN05)
            BigDecimal precioUnitario = stock.getEspProducto().getPrecioUnitario();
            
            // Creamos la línea de venta
            LineaVenta linea = new LineaVenta(venta, stock, dto.cantidad(), precioUnitario);
            venta.addLinea(linea);

            // Calculamos subtotal
            totalAcumulado = totalAcumulado.add(precioUnitario.multiply(new BigDecimal(dto.cantidad())));
        }

        venta.setTotal(totalAcumulado);
        Venta ventaGuardada = ventaRepository.save(venta);

        // Registro de Pago
        PagoVenta pago = new PagoVenta(ventaGuardada, totalAcumulado, request.metodoPago());
        pagoRepository.save(pago);

        // Registro Financiero (Ingreso)
        MovFinanciero movimiento = new MovFinanciero(
            totalAcumulado, 
            "INGRESO", 
            "Venta de productos - ID: " + ventaGuardada.getId(), 
            pago
        );
        movFinancieroRepository.save(movimiento);
    }
}