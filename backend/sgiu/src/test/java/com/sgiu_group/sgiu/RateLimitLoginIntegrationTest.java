package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * A2: 5 credenciales incorrectas seguidas bloquean el login 15 minutos (429).
 * Los usuarios de cada test son únicos porque LoginAttemptService vive en
 * memoria y no se revierte con @Transactional.
 */
class RateLimitLoginIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    private static String loginBody(String user, String pass) {
        return "{\"username\": \"" + user + "\", \"password\": \"" + pass + "\"}";
    }

    @Test
    void cincoFallos_bloqueanElSextoIntento_inclusoConPasswordCorrecta() throws Exception {
        datos.crearUsuario("rl_user_bloqueo", "secreto-bien", true);

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(loginBody("rl_user_bloqueo", "mala-" + i)))
                    .andExpect(status().isUnauthorized());
        }

        // El sexto intento queda bloqueado aunque la contraseña sea correcta.
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("rl_user_bloqueo", "secreto-bien")))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("Demasiados intentos")));
    }

    @Test
    void losFallosDeUnUsuario_noBloqueanAOtro() throws Exception {
        datos.crearUsuario("rl_user_victima", "clave", true);
        datos.crearUsuario("rl_user_inocente", "clave", true);

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(loginBody("rl_user_victima", "mala-" + i)))
                    .andExpect(status().isUnauthorized());
        }

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("rl_user_inocente", "clave")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }

    @Test
    void unLoginCorrecto_limpiaElContadorDeFallos() throws Exception {
        datos.crearUsuario("rl_user_recupero", "clave-correcta", true);

        for (int i = 0; i < 4; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(loginBody("rl_user_recupero", "mala-" + i)))
                    .andExpect(status().isUnauthorized());
        }

        // El quinto intento es correcto: entra y limpia el historial.
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("rl_user_recupero", "clave-correcta")))
                .andExpect(status().isOk());

        // Un fallo posterior vuelve a ser 401 normal, no 429.
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("rl_user_recupero", "mala-de-nuevo")))
                .andExpect(status().isUnauthorized());
    }
}
