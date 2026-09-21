package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WithMockUser
class DashboardControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    private final String fechaDesde = LocalDate.now().minusDays(30).toString();
    private final String fechaHasta = LocalDate.now().toString();

    @Test
    void obtenerDashboard_conDatos_devuelveKpisYGraficos() throws Exception {
        EspProducto producto = datos.crearProducto("DSH-1", "Producto D", new BigDecimal("100.00"), 5, 10);
        datos.crearVenta(producto, 2, "EFECTIVO", LocalDateTime.now());
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal("50.00"), "EFECTIVO",
                "Compras", LocalDateTime.now());

        mockMvc.perform(get("/api/dashboard")
                        .param("fechaDesde", fechaDesde)
                        .param("fechaHasta", fechaHasta))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.metadata.hayDatos").value(true))
                .andExpect(jsonPath("$.metadata.mensaje").value("Dashboard generado correctamente"))
                .andExpect(jsonPath("$.kpis.cantidadVentas").value(1))
                .andExpect(jsonPath("$.kpis.cantidadProductosStockBajo").value(1))
                .andExpect(jsonPath("$.kpis.ingresosPeriodo").isNumber())
                .andExpect(jsonPath("$.kpis.egresosPeriodo").isNumber())
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[0].metodoPago").value("EFECTIVO"))
                .andExpect(jsonPath("$.graficos.productosConMenorStock[0].estado").value("BAJO"));
    }

    @Test
    void obtenerDashboard_sinDatos_loComunicaEnMetadata() throws Exception {
        mockMvc.perform(get("/api/dashboard")
                        .param("fechaDesde", fechaDesde)
                        .param("fechaHasta", fechaHasta))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.metadata.hayDatos").value(false))
                .andExpect(jsonPath("$.metadata.mensaje").value("No hay datos para el período seleccionado"))
                .andExpect(jsonPath("$.kpis.cantidadVentas").value(0))
                .andExpect(jsonPath("$.kpis.ticketPromedio").value(0));
    }

    @Test
    void obtenerDashboard_fechasInvalidas_devuelve400() throws Exception {
        mockMvc.perform(get("/api/dashboard")
                        .param("fechaDesde", fechaHasta)
                        .param("fechaHasta", fechaDesde))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("FECHAS_INVALIDAS"));
    }

    @Test
    void obtenerDashboard_metodoPagoInvalido_devuelve400() throws Exception {
        mockMvc.perform(get("/api/dashboard")
                        .param("fechaDesde", fechaDesde)
                        .param("fechaHasta", fechaHasta)
                        .param("metodoPago", "CREDITO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("FILTRO_INVALIDO"));
    }

    @Test
    void obtenerDashboard_formatoDeFechaInvalido_devuelve400() throws Exception {
        mockMvc.perform(get("/api/dashboard")
                        .param("fechaDesde", "hoy")
                        .param("fechaHasta", fechaHasta))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Formato de fecha inválido. Use el formato ISO: yyyy-MM-dd."));
    }
}