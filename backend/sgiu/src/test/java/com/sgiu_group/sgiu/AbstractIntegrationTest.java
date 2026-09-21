package com.sgiu_group.sgiu;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

@SpringBootTest
@ActiveProfiles("test")
public abstract class AbstractIntegrationTest {

    @Autowired
    protected JdbcTemplate jdbcTemplate;

    protected void limpiarBaseDatos() {
        try {
            jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        } catch (Exception ignored) {}

        List<String> tablas = List.of(
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