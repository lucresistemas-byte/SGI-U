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
    void register_sinAutenticar_devuelve401() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"user_anonimo\", \"password\": \"clave123\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @org.springframework.security.test.context.support.WithMockUser(roles = "ADMIN")
    void register_comoAdmin_valido_devuelveTokenYUsuarioActivo() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"user_nuevo\", \"password\": \"clave123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.username").value("user_nuevo"))
                .andExpect(jsonPath("$.activo").value(true));
    }

    @Test
    @org.springframework.security.test.context.support.WithMockUser(roles = "ADMIN")
    void register_comoAdmin_usuarioDuplicado_devuelve400() throws Exception {
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

    // ------------------------------------------------------------------
    // REG-04: el flujo autenticado de cambio de contraseña no se rompe con
    // la nueva recuperación.
    // ------------------------------------------------------------------

    @Test
    @org.springframework.security.test.context.support.WithMockUser(username = "user_reg_cambio")
    void cambiarPassword_actualCorrecta_permiteLoginConLaNueva() throws Exception {
        datos.crearUsuario("user_reg_cambio", "vieja123", true);

        mockMvc.perform(post("/api/auth/cambiar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"passwordActual\": \"vieja123\", \"passwordNueva\": \"nueva123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        mockMvc.perform(login("user_reg_cambio", "nueva123")).andExpect(status().isOk());
        mockMvc.perform(login("user_reg_cambio", "vieja123")).andExpect(status().isUnauthorized());
    }

    @Test
    @org.springframework.security.test.context.support.WithMockUser(username = "user_reg_cambio_mal")
    void cambiarPassword_actualIncorrecta_devuelve400() throws Exception {
        datos.crearUsuario("user_reg_cambio_mal", "vieja123", true);

        mockMvc.perform(post("/api/auth/cambiar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"passwordActual\": \"otra\", \"passwordNueva\": \"nueva123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("La contraseña actual no es correcta"));
    }
}