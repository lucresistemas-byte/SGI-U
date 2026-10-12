package com.sgiu_group.sgiu;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class DashboardIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser
    void siembraProductosConStockBajoYVerificaKpi() throws Exception {
        limpiarBaseDatos();

        // Producto A: cantidad (5) <= stockMinimo (10) -> stock bajo
        jdbcTemplate.execute("INSERT INTO esp_productos (id, codigo, nombre, tipo, vendible, version, precio_unitario, activo, created_at, updated_at) VALUES (1, 'PROD-A', 'Producto A', 'REVENTA', 1, 0, 10.00, 1, NOW(), NOW())");
        jdbcTemplate.execute("INSERT INTO articulos_stock (id, esp_producto_id, cantidad, stock_minimo, version, created_at, updated_at) VALUES (1, 1, 5, 10, 0, NOW(), NOW())");

        // Producto B: cantidad (10) <= stockMinimo (10) -> stock bajo (caso borde: igualdad)
        jdbcTemplate.execute("INSERT INTO esp_productos (id, codigo, nombre, tipo, vendible, version, precio_unitario, activo, created_at, updated_at) VALUES (2, 'PROD-B', 'Producto B', 'REVENTA', 1, 0, 20.00, 1, NOW(), NOW())");
        jdbcTemplate.execute("INSERT INTO articulos_stock (id, esp_producto_id, cantidad, stock_minimo, version, created_at, updated_at) VALUES (2, 2, 10, 10, 0, NOW(), NOW())");

        // Producto C: cantidad (50) > stockMinimo (10) -> stock normal
        jdbcTemplate.execute("INSERT INTO esp_productos (id, codigo, nombre, tipo, vendible, version, precio_unitario, activo, created_at, updated_at) VALUES (3, 'PROD-C', 'Producto C', 'REVENTA', 1, 0, 30.00, 1, NOW(), NOW())");
        jdbcTemplate.execute("INSERT INTO articulos_stock (id, esp_producto_id, cantidad, stock_minimo, version, created_at, updated_at) VALUES (3, 3, 50, 10, 0, NOW(), NOW())");

        mockMvc.perform(get("/api/dashboard")
                        .param("fechaDesde", LocalDate.now().minusDays(30).toString())
                        .param("fechaHasta", LocalDate.now().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kpis.cantidadProductosStockBajo").value(2));
    }
}