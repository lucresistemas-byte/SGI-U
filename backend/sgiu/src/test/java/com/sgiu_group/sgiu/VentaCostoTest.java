package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.LineaVenta;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.LineaVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import com.sgiu_group.sgiu.services.VentaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class VentaCostoTest extends AbstractIntegrationTest {

    @Autowired
    private EspProductoRepository productoRepository;

    @Autowired
    private ArticuloStockRepository stockRepository;

    @Autowired
    private VentaService ventaService;

    @Autowired
    private LineaVentaRepository lineaVentaRepository;

    @Autowired
    private VentaRepository ventaRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void costoUnitarioQuedaCongeladoEnLineaVenta() {
        EspProducto prod = new EspProducto("PROD-COSTO-FREEZE", "Café Tostado", new BigDecimal("125.00"));
        prod.setPrecioCosto(new BigDecimal("100.00"));
        prod = productoRepository.save(prod);

        ArticuloStock stock = new ArticuloStock(prod, 10);
        stockRepository.save(stock);

        VentaRequestDTO request = new VentaRequestDTO(
                List.of(new LineaVentaDTO("PROD-COSTO-FREEZE", 2)),
                "EFECTIVO"
        );
        ventaService.procesarVenta(request);

        List<LineaVenta> lineas = lineaVentaRepository.findAll();
        assertFalse(lineas.isEmpty());
        LineaVenta linea = lineas.get(0);
        assertEquals(0, new BigDecimal("100.00").compareTo(linea.getCostoUnitario()));
        assertEquals(0, new BigDecimal("250.00").compareTo(linea.getSubtotal()));
        assertEquals(0, new BigDecimal("50.00").compareTo(linea.calcularGanancia()));

        // Cambio posterior en el costo del catálogo
        prod.setPrecioCosto(new BigDecimal("110.00"));
        productoRepository.save(prod);

        // La línea de venta debe seguir manteniendo 100.00
        LineaVenta lineaPostCambio = lineaVentaRepository.findById(linea.getId()).orElse(null);
        assertNotNull(lineaPostCambio);
        assertEquals(0, new BigDecimal("100.00").compareTo(lineaPostCambio.getCostoUnitario()));
    }
}
