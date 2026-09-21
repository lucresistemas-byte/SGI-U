package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    private MockHttpServletRequestBuilder login(String user, String pass) {
        return post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\": \"" + user + "\", \"password\": \"" + pass + "\"}");
    }

    @Test
    void register_valido_devuelveTokenYUsuarioActivo() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"user_nuevo\", \"password\": \"clave123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.username").value("user_nuevo"))
                .andExpect(jsonPath("$.activo").value(true));
    }

    @Test
    void register_usuarioDuplicado_devuelve400() throws Exception {
        datos.crearUsuario("user_dup", "clave123", true);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"user_dup\", \"password\": \"otra\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El nombre de usuario ya está en uso"));
    }

    @Test
    void login_credencialesCorrectas_devuelveToken() throws Exception {
        datos.crearUsuario("user_login", "secreto", true);

        mockMvc.perform(login("user_login", "secreto"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.username").value("user_login"));
    }

    @Test
    void login_contrasenaIncorrecta_devuelve401() throws Exception {
        datos.crearUsuario("user_mal_pass", "secreto", true);

        mockMvc.perform(login("user_mal_pass", "incorrecta"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Credenciales incorrectas"));
    }

    @Test
    void login_usuarioInexistente_devuelve401() throws Exception {
        mockMvc.perform(login("user_no_existe", "cualquiera"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Credenciales incorrectas"));
    }
}