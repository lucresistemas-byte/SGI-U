package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.DockerClientFactory;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.Connection;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Smoke test del perfil "integration": arranca la app contra un MariaDB de
 * Testcontainers (no contra la base instalada) y persiste un producto. Si
 * Docker no está accesible, se saltea.
 */
@SpringBootTest
@ActiveProfiles("integration")
@EnabledIf("dockerDisponible")
@Transactional
class MariaDbIntegrationTest {

    static boolean dockerDisponible() {
        try {
            return DockerClientFactory.instance().isDockerAvailable();
        } catch (Throwable e) {
            return false;
        }
    }

    @Autowired
    private DataSource dataSource;
    @Autowired
    private EspProductoRepository productoRepository;

    @Test
    void usaUnMariaDbDescartableYPersiste() throws Exception {
        try (Connection c = dataSource.getConnection()) {
            assertThat(c.getMetaData().getDatabaseProductVersion()).containsIgnoringCase("MariaDB");
            assertThat(c.getMetaData().getURL()).doesNotContain(":3307").doesNotContain("sgiu_db");
        }

        productoRepository.save(new EspProducto("IT-001", "Producto IT", new BigDecimal("10.00")));

        assertThat(productoRepository.findByCodigo("IT-001")).isPresent();
    }
}
