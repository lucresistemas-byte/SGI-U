package com.sgiu_group.sgiu.security;

import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;

/**
 * Limitador de tasa de intentos de autenticación (Rate Limiting).
 * Bloquea temporalmente el acceso por 15 minutos tras 5 intentos fallidos consecutivos.
 * Cumple con OWASP ASVS v4.0 (V2/V3), NIST SP 800-63B y OWASP API Security (API4:2023).
 */
@Component
public class LoginRateLimiter {

    public static final int MAX_INTENTOS = 5;
    public static final long TIEMPO_BLOQUEO_MS = 15 * 60 * 1000L; // 15 minutos

    private static class IntentoInfo {
        int fallos;
        long bloqueadoHasta;
    }

    private final ConcurrentHashMap<String, IntentoInfo> intentosPorClave = new ConcurrentHashMap<>();

    public boolean estaBloqueado(String clave) {
        if (clave == null || clave.isBlank()) {
            return false;
        }
        IntentoInfo info = intentosPorClave.get(clave.toLowerCase().trim());
        if (info == null) {
            return false;
        }
        long ahora = System.currentTimeMillis();
        if (ahora < info.bloqueadoHasta) {
            return true;
        }
        if (info.bloqueadoHasta > 0 && ahora >= info.bloqueadoHasta) {
            // El período de bloqueo expiró, se limpia el registro
            intentosPorClave.remove(clave.toLowerCase().trim());
            return false;
        }
        return false;
    }

    public long getMinutosRestantesBloqueo(String clave) {
        if (clave == null || clave.isBlank()) {
            return 0;
        }
        IntentoInfo info = intentosPorClave.get(clave.toLowerCase().trim());
        if (info == null || System.currentTimeMillis() >= info.bloqueadoHasta) {
            return 0;
        }
        long msRestantes = info.bloqueadoHasta - System.currentTimeMillis();
        return Math.max(1, (msRestantes + 59999L) / (60 * 1000L));
    }

    public void registrarFallo(String clave) {
        if (clave == null || clave.isBlank()) {
            return;
        }
        intentosPorClave.compute(clave.toLowerCase().trim(), (k, v) -> {
            if (v == null) {
                v = new IntentoInfo();
            }
            v.fallos++;
            if (v.fallos >= MAX_INTENTOS) {
                v.bloqueadoHasta = System.currentTimeMillis() + TIEMPO_BLOQUEO_MS;
            }
            return v;
        });
    }

    public void resetear(String clave) {
        if (clave != null && !clave.isBlank()) {
            intentosPorClave.remove(clave.toLowerCase().trim());
        }
    }

    public void limpiarTodo() {
        intentosPorClave.clear();
    }
}
