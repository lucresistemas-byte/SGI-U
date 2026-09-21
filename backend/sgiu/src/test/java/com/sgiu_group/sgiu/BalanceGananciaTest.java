package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.services.MovimientoService;
import com.sgiu_group.sgiu.services.VentaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class BalanceGananciaTest extends AbstractIntegrationTest {

    @Autowired
    private EspProductoRepository productoRepository;

    @Autowired
    private ArticuloStockRepository stockRepository;

    @Autowired
    private VentaService ventaService;

    @Autowired
    private MovimientoService movimientoService;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void calcularBalanceConCostosYGananciaReal() {
        // Producto con costo definido
        EspProducto p1 = new EspProducto("P-CON-COSTO", "Harina 1kg", new BigDecimal("200.00"));
        p1.setPrecioCosto(new BigDecimal("120.00"));
        p1 = productoRepository.save(p1);
        stockRepository.save(new ArticuloStock(p1, 20));

        // Venta de 2 unidades -> Ingreso: 400.00, Costo: 240.00, Ganancia: 160.00
        ventaService.procesarVenta(new VentaRequestDTO(
                List.of(new LineaVentaDTO("P-CON-COSTO", 2)),
                "EFECTIVO"
        ));

        BalanceResponseDTO balance = movimientoService.calcularBalance(LocalDate.now(), LocalDate.now());
        assertNotNull(balance);
        assertEquals(0, new BigDecimal("400.00").compareTo(balance.totalIngresos()));
        assertEquals(0, new BigDecimal("240.00").compareTo(balance.costoTotal()));
        assertEquals(0, new BigDecimal("160.00").compareTo(balance.gananciaReal()));
    }

    @Test
    void ventaSinCostoAsumeGananciaIgualAImporte() {
        EspProducto p2 = new EspProducto("P-SIN-COSTO", "Servicio artesanal", new BigDecimal("300.00"));
        p2.setPrecioCosto(BigDecimal.ZERO);
        p2 = productoRepository.save(p2);
        stockRepository.save(new ArticuloStock(p2, 10));

        ventaService.procesarVenta(new VentaRequestDTO(
                List.of(new LineaVentaDTO("P-SIN-COSTO", 1)),
                "EFECTIVO"
        ));

        BalanceResponseDTO balance = movimientoService.calcularBalance(LocalDate.now(), LocalDate.now());
        assertNotNull(balance);
        assertEquals(0, new BigDecimal("300.00").compareTo(balance.totalIngresos()));
        assertEquals(0, BigDecimal.ZERO.compareTo(balance.costoTotal()));
        assertEquals(0, new BigDecimal("300.00").compareTo(balance.gananciaReal()));
    }
}
