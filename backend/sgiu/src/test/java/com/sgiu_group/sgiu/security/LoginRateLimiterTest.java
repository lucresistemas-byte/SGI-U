package com.sgiu_group.sgiu.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LoginRateLimiterTest {

    private LoginRateLimiter rateLimiter;

    @BeforeEach
    void setUp() {
        rateLimiter = new LoginRateLimiter();
    }

    @Test
    void antesDeCincoFallos_noEstaBloqueado() {
        String usuario = "admin";

        for (int i = 0; i < 4; i++) {
            rateLimiter.registrarFallo(usuario);
            assertThat(rateLimiter.estaBloqueado(usuario)).isFalse();
        }
    }

    @Test
    void alQuintoFallo_seBloqueaPorQuinceMinutos() {
        String usuario = "admin";

        for (int i = 0; i < 5; i++) {
            rateLimiter.registrarFallo(usuario);
        }

        assertThat(rateLimiter.estaBloqueado(usuario)).isTrue();
        assertThat(rateLimiter.getMinutosRestantesBloqueo(usuario)).isGreaterThanOrEqualTo(14L);
    }

    @Test
    void loginExitoso_reseteaIntentos() {
        String usuario = "admin";

        for (int i = 0; i < 4; i++) {
            rateLimiter.registrarFallo(usuario);
        }

        rateLimiter.resetear(usuario);
        assertThat(rateLimiter.estaBloqueado(usuario)).isFalse();

        // 4 fallos adicionales tras resetear no deben bloquearlo
        for (int i = 0; i < 4; i++) {
            rateLimiter.registrarFallo(usuario);
        }
        assertThat(rateLimiter.estaBloqueado(usuario)).isFalse();
    }

    @Test
    void usuariosDistintos_tienenContadoresIndependientes() {
        rateLimiter.registrarFallo("admin");
        rateLimiter.registrarFallo("admin");
        rateLimiter.registrarFallo("admin");
        rateLimiter.registrarFallo("admin");
        rateLimiter.registrarFallo("admin");

        assertThat(rateLimiter.estaBloqueado("admin")).isTrue();
        assertThat(rateLimiter.estaBloqueado("otro_usuario")).isFalse();
    }
}
