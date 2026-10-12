package com.sgiu_group.sgiu;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.DockerClientFactory;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Etapa 1: V1 (esquema) y V1.1 (datos de demo) se aplican sobre un MariaDB
 * real (Testcontainers) y Hibernate valida las entidades contra ese esquema
 * (ddl-auto: validate en el perfil integration): si el contexto arranca, el
 * esquema y el mapeo coinciden. Se saltea si Docker no está accesible.
 */
@SpringBootTest(properties = "spring.flyway.locations=classpath:db/migration,classpath:db/demo")
@ActiveProfiles("integration")
@EnabledIf("dockerDisponible")
class FlywayMariaDbTest {

    static boolean dockerDisponible() {
        try {
            return DockerClientFactory.instance().isDockerAvailable();
        } catch (Throwable e) {
            return false;
        }
    }

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void aplicaV1YLaDemoYLasEntidadesValidan() {
        assertThat(jdbc.queryForList(
                "SELECT version FROM flyway_schema_history WHERE success = 1 ORDER BY installed_rank", String.class))
                .containsExactly("1", "1.1");

        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM esp_productos", Integer.class)).isEqualTo(7);
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM esp_productos WHERE tipo = 'ELABORADO' AND vendible = 0", Integer.class))
                .isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM recetas", Integer.class)).isEqualTo(4);
    }

    @Test
    void elCheckImpideQueUnaReventaSeaPreparacionBase() {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO esp_productos (created_at, updated_at, activo, codigo, nombre, tipo, vendible, precio_unitario) "
                        + "VALUES (NOW(6), NOW(6), 1, 'X-1', 'X', 'REVENTA', 0, 1)"))
                .hasMessageContaining("ck_preparacion_base");
    }
}
