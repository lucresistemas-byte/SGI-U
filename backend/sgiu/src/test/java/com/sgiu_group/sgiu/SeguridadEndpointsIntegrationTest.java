package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sgiu_group.sgiu.security.LoginRateLimiter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class SeguridadEndpointsIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private LoginRateLimiter loginRateLimiter;

    @Autowired
    private com.sgiu_group.sgiu.support.TestDataFactory datos;

    @BeforeEach
    void resetLimiter() {
        loginRateLimiter.limpiarTodo();
    }

    @Test
    void endpointProtegido_sinToken_devuelve401() throws Exception {
        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("No autorizado"));
    }

    @Test
    void endpointProtegido_tokenMalFormado_devuelve401() throws Exception {
        mockMvc.perform(get("/api/productos")
                        .header("Authorization", "Bearer no-es-un-jwt"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Token inválido o expirado"));
    }

    @Test
    void endpointProtegido_tokenValido_dejaPasar() throws Exception {
        datos.crearUsuario("user_token_valido", "clave123", true);

        String body = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"user_token_valido\", \"password\": \"clave123\"}"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode json = objectMapper.readTree(body);
        String token = json.get("token").asText();
        assertThat(token).isNotBlank();

        mockMvc.perform(get("/api/productos")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    @Test
    void headersDeSeguridad_estanPresentesEnRespuestasHttp() throws Exception {
        mockMvc.perform(get("/api/configuracion/marca"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Frame-Options", "DENY"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().exists("Content-Security-Policy"));
    }

    @Test
    void recursoWebBackups_noEsAccesibleComoArchivoEstatico() throws Exception {
        // Valida que /backups/... no se exponga como contenido web estático
        mockMvc.perform(get("/backups/sgiu_dump_sensible.sql.gz.enc"))
                .andExpect(status().isUnauthorized()); // Interceptado por seguridad / no servido públicamente
    }

    @Test
    void rateLimiterLogin_cincoIntentosFallidos_devuelve429() throws Exception {
        String badPayload = "{\"username\": \"admin_fuerza_bruta\", \"password\": \"clave_erronea\"}";

        // 4 intentos fallidos devuelven 401
        for (int i = 0; i < 4; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(badPayload))
                    .andExpect(status().isUnauthorized());
        }

        // El 5to intento fallido activa el bloqueo y devuelve 429 TOO_MANY_REQUESTS
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(badPayload))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error").exists());
    }
}
