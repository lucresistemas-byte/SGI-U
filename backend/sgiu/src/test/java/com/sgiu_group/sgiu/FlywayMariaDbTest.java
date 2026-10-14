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
                .containsExactly("1", "1.1", "2", "3", "3.1", "4", "5", "5.1", "6", "6.1", "7", "7.1");

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

        // 8 materias primas, 4 insumos (V7.1 suma el papel) y la caja de chocolate, con su stock en unidad base.
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM esp_productos p JOIN articulos_stock s "
                + "ON s.esp_producto_id = p.id WHERE p.tipo IN ('MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA')",
                Integer.class)).isEqualTo(13);
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

        // Las filas de recetas apuntan a artículos de materia prima o a preparaciones base.
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM recetas_detalles d JOIN esp_productos a "
                + "ON a.id = d.articulo_id WHERE a.tipo NOT IN ('MATERIA_PRIMA','INSUMO','REVENTA_MATERIA_PRIMA') "
                + "AND NOT (a.tipo = 'ELABORADO' AND a.vendible = 0)", Integer.class)).isZero();
    }

    @Test
    void elCheckImpideQueUnaReventaSeaPreparacionBase() {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO esp_productos (created_at, updated_at, activo, codigo, nombre, tipo, vendible, precio_unitario) "
                        + "VALUES (NOW(6), NOW(6), 1, 'X-1', 'X', 'REVENTA', 0, 1)"))
                .hasMessageContaining("ck_preparacion_base");
    }

    /** Etapa 4: ganache como preparación base (800 g) dentro de la torta, paquete y precio a mano. */
    @Test
    void motorDePrecios_demoYEsquema() {
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() "
                + "AND table_name = 'esp_productos' AND column_name = 'precio_manual'", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT r.rinde_unidad_medida FROM recetas r JOIN esp_productos p "
                + "ON p.id = r.esp_producto_id WHERE p.codigo = 'ELA-0004'", String.class)).isEqualTo("GRAMO");
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM recetas_detalles d JOIN esp_productos a ON a.id = d.articulo_id "
                + "JOIN recetas r ON r.id = d.receta_id JOIN esp_productos p ON p.id = r.esp_producto_id "
                + "WHERE a.codigo = 'ELA-0004' AND p.codigo = 'ELA-0002'", Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT precio_unitario FROM esp_productos WHERE codigo = 'PAQ-0001'",
                java.math.BigDecimal.class)).isEqualByComparingTo("3800");
        assertThat(jdbc.queryForObject("SELECT modo_precio FROM esp_productos WHERE codigo = 'REV-0003'", String.class))
                .isEqualTo("MANUAL");
        // Todos los precios de venta son múltiplos de $100.
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM esp_productos WHERE MOD(precio_unitario, 100) <> 0",
                Integer.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM historial_precios", Integer.class)).isZero();
    }
}
