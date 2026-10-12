package com.sgiu_group.sgiu.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * El perfil "integration" apuntaba a jdbc:mariadb://localhost:3307/sgiu_db, el
 * MariaDB que instala SGI-U: unos tests que limpian tablas podían borrar los
 * datos de una instalación real. Debe usar una base descartable de
 * Testcontainers. No necesita Docker: solo lee la configuración.
 */
class PerfilIntegrationSeguroTest {

    private Properties perfilIntegration() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application-integration.yml"));
        return yaml.getObject();
    }

    @Test
    void elPerfilIntegrationUsaTestcontainersYNuncaLaBaseInstalada() {
        String url = perfilIntegration().getProperty("spring.datasource.url");

        assertThat(url).startsWith("jdbc:tc:mariadb:");
        assertThat(url).doesNotContain("3307").doesNotContain("sgiu_db").doesNotContain("localhost");
    }

    @Test
    void elPerfilIntegrationNoCargaDatosDeDemo() {
        assertThat(perfilIntegration().getProperty("spring.sql.init.mode")).isEqualTo("never");
    }
}
