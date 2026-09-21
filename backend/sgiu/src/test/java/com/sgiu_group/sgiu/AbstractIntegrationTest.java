package com.sgiu_group.sgiu;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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
        try {
            jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        } catch (Exception ignored) {}

        List<String> tablas = List.of(
                "pedidos_abonos",
                "pedidos",
                "recetas_detalles",
                "recetas",
                "materias_primas",
                "movimientos_financieros",
                "articulos_stock",
                "lineas_venta",
                "pagos_venta",
                "ventas",
                "esp_productos",
                "categorias",
                "configuracion_negocio",
                "esp_usuarios"
        );

        for (String tabla : tablas) {
            try {
                jdbcTemplate.execute("DELETE FROM " + tabla);
            } catch (Exception ignored) {}
        }

        try {
            jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
        } catch (Exception ignored) {}
    }
}