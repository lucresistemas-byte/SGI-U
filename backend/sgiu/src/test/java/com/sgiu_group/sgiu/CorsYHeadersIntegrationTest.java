package com.sgiu_group.sgiu;

import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * A2: headers de seguridad HTTP y allowlist CORS (el navegador solo acepta
 * respuestas del frontend autorizado; orígenes ajenos no pasan el preflight).
 */
class CorsYHeadersIntegrationTest extends AbstractIntegrationTest {

    @Test
    void login_llevaLosHeadersDeSeguridad() throws Exception {
        mockMvc.perform(get("/api/auth/login"))
                .andExpect(status().is4xxClientError())
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("X-Frame-Options", "DENY"));
    }

    @Test
    void preflight_deOrigenNoListado_seRechaza() throws Exception {
        mockMvc.perform(options("/api/productos")
                        .header("Origin", "http://evil.example.com")
                        .header("Access-Control-Request-Method", "GET")
                        .header("Access-Control-Request-Headers", "Authorization"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @Test
    void preflight_deOrigenPermitido_llevaElHeader() throws Exception {
        mockMvc.perform(options("/api/productos")
                        .header("Origin", "http://localhost:5173")
                        .header("Access-Control-Request-Method", "GET")
                        .header("Access-Control-Request-Headers", "Authorization"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:5173"));
    }

    @Test
    void get_sencilloDeOrigenNoListado_noDeclaraOrigen() throws Exception {
        mockMvc.perform(get("/api/auth/login")
                        .header("Origin", "http://evil.example.com"))
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }
}
