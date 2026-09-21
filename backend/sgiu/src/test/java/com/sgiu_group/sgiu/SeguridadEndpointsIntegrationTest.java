package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class SeguridadEndpointsIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private ObjectMapper objectMapper;

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
        String body = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"user_token\", \"password\": \"clave123\"}"))
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
}