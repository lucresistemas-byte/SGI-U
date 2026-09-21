package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.services.DashboardService;
import com.sgiu_group.sgiu.services.VentaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class DashboardCategoriaTest extends AbstractIntegrationTest {

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private EspProductoRepository productoRepository;

    @Autowired
    private ArticuloStockRepository stockRepository;

    @Autowired
    private VentaService ventaService;

    @Autowired
    private DashboardService dashboardService;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    void categoriaMasVendidaReflejaMayorMontoEnDashboard() {
        Categoria catComida = categoriaRepository.save(new Categoria("Comida"));
        Categoria catBebida = categoriaRepository.save(new Categoria("Bebida"));

        EspProducto pComida = new EspProducto("P-BURGER", "Hamburguesa", new BigDecimal("1000.00"));
        pComida.setCategoria(catComida);
        pComida = productoRepository.save(pComida);
        stockRepository.save(new ArticuloStock(pComida, 50));

        EspProducto pBebida = new EspProducto("P-SODA", "Gaseosa", new BigDecimal("200.00"));
        pBebida.setCategoria(catBebida);
        pBebida = productoRepository.save(pBebida);
        stockRepository.save(new ArticuloStock(pBebida, 50));

        // Venta Comida: 3 x 1000 = 3000
        ventaService.procesarVenta(new VentaRequestDTO(List.of(new LineaVentaDTO("P-BURGER", 3)), "EFECTIVO"));
        // Venta Bebida: 2 x 200 = 400
        ventaService.procesarVenta(new VentaRequestDTO(List.of(new LineaVentaDTO("P-SODA", 2)), "EFECTIVO"));

        DashboardResponseDTO dashboard = dashboardService.obtenerDashboard(
                LocalDate.now(), LocalDate.now(), null, null, null
        );

        assertNotNull(dashboard);
        assertNotNull(dashboard.getGraficos().getCategoriaMasVendida());
        assertEquals("Comida", dashboard.getGraficos().getCategoriaMasVendida().nombre());
        assertEquals(0, new BigDecimal("3000.00").compareTo(dashboard.getGraficos().getCategoriaMasVendida().montoTotal()));
    }
}
