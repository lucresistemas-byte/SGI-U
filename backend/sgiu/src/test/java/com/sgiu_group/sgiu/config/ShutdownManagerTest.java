package com.sgiu_group.sgiu.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThatCode;

@SpringBootTest
@ActiveProfiles("test")
class ShutdownManagerTest {

    @Autowired
    private ShutdownManager shutdownManager;

    @Test
    void shutdownEsIdempotente() {
        assertThatCode(() -> {
            shutdownManager.shutdown();
            shutdownManager.shutdown();
        }).doesNotThrowAnyException();
    }
}