package com.sgiu_group.sgiu;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
public abstract class AbstractIntegrationTest {

    @Autowired
    protected JdbcTemplate jdbcTemplate;

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