package com.sgiu_group.sgiu.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RL-07 / RL-08: vencimiento del bloqueo con reloj controlable y aislamiento
 * entre instancias (el contador vive en memoria).
 */
class LoginAttemptServiceTest {

    /** Reloj controlable para probar el vencimiento sin esperar 15 minutos. */
    private static final class RelojControlable extends Clock {
        private Instant instante = Instant.parse("2026-01-01T00:00:00Z");

        void avanzar(Duration duracion) {
            instante = instante.plus(duracion);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return instante;
        }
    }

    @Test
    @DisplayName("RL-07: el bloqueo vence a los 15 minutos")
    void bloqueoVenceALos15Minutos() {
        RelojControlable reloj = new RelojControlable();
        LoginAttemptService servicio = new LoginAttemptService(reloj);

        for (int i = 0; i < 5; i++) {
            servicio.registrarFallo("usuario_rl07");
        }
        assertThat(servicio.estaBloqueado("usuario_rl07")).isTrue();

        reloj.avanzar(Duration.ofMinutes(16));

        assertThat(servicio.estaBloqueado("usuario_rl07")).isFalse();
    }

    @Test
    @DisplayName("RL-08: una instancia nueva no conserva los bloqueos (contador en memoria)")
    void nuevaInstancia_noConservaBloqueos() {
        LoginAttemptService primera = new LoginAttemptService(new RelojControlable());
        for (int i = 0; i < 5; i++) {
            primera.registrarFallo("usuario_rl08");
        }
        assertThat(primera.estaBloqueado("usuario_rl08")).isTrue();

        LoginAttemptService segunda = new LoginAttemptService(new RelojControlable());
        assertThat(segunda.estaBloqueado("usuario_rl08")).isFalse();
    }
}
