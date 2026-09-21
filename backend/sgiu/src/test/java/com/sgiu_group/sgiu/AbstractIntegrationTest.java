package com.sgiu_group.sgiu;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@AutoConfigureMockMvc
@Transactional
public abstract class AbstractIntegrationTest {

    @Autowired
    protected JdbcTemplate jdbcTemplate;

    @Autowired
    protected MockMvc mockMvc;

    /**
     * Como las clases de integración son @Transactional, cada test revierte sus
     * escrituras al final. Este método se conserva por compatibilidad con tests
     * previos que dependían de la limpieza manual.
     */
    protected void limpiarBaseDatos() {
        jdbcTemplate.execute("DELETE FROM movimientos_financieros");
        jdbcTemplate.execute("DELETE FROM articulos_stock");
        jdbcTemplate.execute("DELETE FROM lineas_venta");
        jdbcTemplate.execute("DELETE FROM pagos_venta");
        jdbcTemplate.execute("DELETE FROM ventas");
        jdbcTemplate.execute("DELETE FROM esp_productos");
        jdbcTemplate.execute("DELETE FROM esp_usuarios");
    }
}