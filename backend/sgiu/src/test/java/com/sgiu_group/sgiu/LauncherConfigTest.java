package com.sgiu_group.sgiu;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.env.Environment;

import static org.assertj.core.api.Assertions.assertThat;

class LauncherConfigTest {

    private ConfigurableApplicationContext context;

    @AfterEach
    void tearDown() {
        if (context != null) {
            context.close();
        }
    }

    @Test
    void propagaPuertoYDireccionAlEnvironmentDeSpring() {
        SpringApplicationBuilder builder = new SpringApplicationBuilder(SgiuApplication.class);
        builder.profiles("test");
        builder.properties(
            "server.port=3000",
            "server.address=0.0.0.0"
        );

        context = builder.run();
        Environment env = context.getEnvironment();

        assertThat(env.getProperty("server.port")).isEqualTo("3000");
        assertThat(env.getProperty("server.address")).isEqualTo("0.0.0.0");
    }
}