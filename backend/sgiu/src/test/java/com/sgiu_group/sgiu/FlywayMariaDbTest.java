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
 * Todas las migraciones y los datos de demo se aplican sobre un MariaDB real
 * vacío (Testcontainers) y Hibernate valida las entidades contra ese esquema
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
    void aplicaTodasLasMigracionesYLaDemoYLasEntidadesValidan() {
        assertThat(jdbc.queryForList(
                "SELECT version FROM flyway_schema_history WHERE success = 1 ORDER BY installed_rank", String.class))
                .containsExactly("1", "1.1", "2", "3", "3.1", "4", "5", "5.1", "6", "6.1");

        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM esp_productos WHERE tipo = 'ELABORADO' AND vendible = 0", Integer.class))
                .isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM recetas", Integer.class)).isEqualTo(6);
    }

    /** Etapa 3: catálogo único. */
    @Test
    void lasMateriasPrimasPasaronAlCatalogo_yLaTablaViejaNoExiste() {
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM information_schema.tables "
                + "WHERE table_schema = DATABASE() AND table_name = 'materias_primas'", Integer.class)).isZero();

        // 8 materias primas, 3 insumos y la caja de chocolate, con su stock en unidad base.
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM esp_productos p JOIN articulos_stock s "
                + "ON s.esp_producto_id = p.id WHERE p.tipo IN ('MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA')",
                Integer.class)).isEqualTo(12);
        assertThat(jdbc.queryForObject("SELECT s.cantidad FROM articulos_stock s JOIN esp_productos p "
                + "ON p.id = s.esp_producto_id WHERE p.codigo = 'MP-0001'", java.math.BigDecimal.class))
                .isEqualByComparingTo("25000");
        assertThat(jdbc.queryForObject("SELECT costo_unidad_base FROM esp_productos WHERE codigo = 'MP-0001'",
                java.math.BigDecimal.class)).isEqualByComparingTo("1.2");

        // La caja de chocolate: 36 cajas y 50 g sueltos; el brownie usa 150 g.
        assertThat(jdbc.queryForObject("SELECT s.cantidad FROM articulos_stock s JOIN esp_productos p "
                + "ON p.id = s.esp_producto_id WHERE p.codigo = 'RMP-0001'", java.math.BigDecimal.class))
                .isEqualByComparingTo("3650");
        assertThat(jdbc.queryForObject("SELECT d.cantidad_base FROM recetas_detalles d "
                + "JOIN esp_productos a ON a.id = d.articulo_id WHERE a.codigo = 'RMP-0001'",
                java.math.BigDecimal.class)).isEqualByComparingTo("150");

        // Todas las filas de recetas apuntan a un artículo de materia prima.
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM recetas_detalles d JOIN esp_productos a "
                + "ON a.id = d.articulo_id WHERE a.tipo NOT IN ('MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA')",
                Integer.class)).isZero();
    }

    @Test
    void elCheckImpideQueUnaReventaSeaPreparacionBase() {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO esp_productos (created_at, updated_at, activo, codigo, nombre, tipo, vendible, precio_unitario) "
                        + "VALUES (NOW(6), NOW(6), 1, 'X-1', 'X', 'REVENTA', 0, 1)"))
                .hasMessageContaining("ck_preparacion_base");
    }
}
