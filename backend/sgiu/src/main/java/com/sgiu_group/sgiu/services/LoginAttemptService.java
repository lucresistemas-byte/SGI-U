package com.sgiu_group.sgiu.services;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A2: límite de intentos de login. Después de {@value #MAX_INTENTOS_FALLOS}
 * credenciales incorrectas seguidas, el usuario queda bloqueado durante
 * {@value #MINUTOS_BLOQUEO} minutos (HTTP 429). Un login correcto limpia el contador.
 * <p>
 * En memoria: el local tiene un único administrador y el backend se reinicia
 * con cada actualización del sistema.
 */
@Service
public class LoginAttemptService {

    static final int MAX_INTENTOS_FALLOS = 5;
    static final long MINUTOS_BLOQUEO = 15;

    private record Intentos(int fallos, Instant ultimoFallo) {}

    private final ConcurrentHashMap<String, Intentos> intentosPorUsuario = new ConcurrentHashMap<>();

    /** true si el usuario está bloqueado por intentos fallidos. */
    public boolean estaBloqueado(String username) {
        if (username == null) {
            return false;
        }
        Intentos intentos = intentosPorUsuario.get(normalizar(username));
        if (intentos == null || intentos.fallos() < MAX_INTENTOS_FALLOS) {
            return false;
        }
        Duration transcurrido = Duration.between(intentos.ultimoFallo(), Instant.now());
        if (transcurrido.toMinutes() >= MINUTOS_BLOQUEO) {
            // Se venció el bloqueo: se limpia y se puede volver a intentar.
            intentosPorUsuario.remove(normalizar(username));
            return false;
        }
        return true;
    }

    /** Registra un intento fallido. Si llega al límite, deja el usuario bloqueado. */
    public void registrarFallo(String username) {
        if (username == null) {
            return;
        }
        intentosPorUsuario.compute(normalizar(username), (k, actuales) -> {
            int fallos = (actuales == null) ? 1 : actuales.fallos() + 1;
            return new Intentos(fallos, Instant.now());
        });
    }

    /** Un login correcto borra el historial de fallos del usuario. */
    public void registrarExito(String username) {
        if (username != null) {
            intentosPorUsuario.remove(normalizar(username));
        }
    }

    /** Minutos que faltan para desbloquear (para el mensaje del 429). */
    public long minutosRestantesDeBloqueo(String username) {
        Intentos intentos = intentosPorUsuario.get(normalizar(username));
        if (intentos == null) {
            return 0;
        }
        Duration transcurrido = Duration.between(intentos.ultimoFallo(), Instant.now());
        long restantes = MINUTOS_BLOQUEO - transcurrido.toMinutes();
        return Math.max(1, restantes);
    }

    private static String normalizar(String username) {
        return username.trim().toLowerCase();
    }
}
