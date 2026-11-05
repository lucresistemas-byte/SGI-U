package com.sgiu_group.sgiu;

import com.jayway.jsonpath.JsonPath;
import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.security.JwtUtil;
import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * IT-01..IT-11, SEG-01..SEG-05, SEG-10, RL-01..RL-06 y VAL-01..VAL-12:
 * endpoint completo de recuperación de contraseña.
 *
 * Cada test usa un usuario único: LoginAttemptService vive en memoria y no se
 * revierte con @Transactional.
 */
class PasswordRecoveryIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    @Autowired
    private EspUsuarioRepository usuarios;

    @Autowired
    private PasswordEncoder encoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private EspUsuarioDetailsService detalles;

    @Value("${sgiu.recovery.key}")
    private String claveRecuperacion;

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private MockHttpServletRequestBuilder recuperar(String username, String clave, String password) {
        return post("/api/auth/recuperar-password")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(username, clave, password));
    }

    private MockHttpServletRequestBuilder login(String user, String pass) {
        return post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\": \"" + user + "\", \"password\": \"" + pass + "\"}");
    }

    /** Serializa a JSON con escape de comillas y backslashes. */
    private static String json(String username, String clave, String password) {
        return "{\"username\": " + jsonString(username)
                + ", \"claveRecuperacion\": " + jsonString(clave)
                + ", \"passwordNueva\": " + jsonString(password) + "}";
    }

    private static String jsonString(String valor) {
        if (valor == null) {
            return "null";
        }
        return "\"" + valor.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    // ------------------------------------------------------------------
    // IT-01..IT-11: integración del endpoint
    // ------------------------------------------------------------------

    @Test
    @DisplayName("IT-01: recuperación exitosa devuelve 200 con mensaje y username")
    void recuperacionExitosa_devuelve200() throws Exception {
        datos.crearUsuario("rec_it01", "vieja123", true);

        mockMvc.perform(recuperar("rec_it01", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mensaje").value(containsString("restablecida")))
                .andExpect(jsonPath("$.username").value("rec_it01"));
    }

    @Test
    @DisplayName("IT-02: luego de recuperar, el login funciona con la contraseña nueva")
    void recuperacionExitosa_permiteLoginConLaNueva() throws Exception {
        datos.crearUsuario("rec_it02", "vieja123", true);

        mockMvc.perform(recuperar("rec_it02", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());

        mockMvc.perform(login("rec_it02", "NuevaClave123")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("IT-03: luego de recuperar, el login con la contraseña anterior falla con 401")
    void recuperacionExitosa_rechazaLoginConLaAnterior() throws Exception {
        datos.crearUsuario("rec_it03", "vieja123", true);

        mockMvc.perform(recuperar("rec_it03", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());

        mockMvc.perform(login("rec_it03", "vieja123")).andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("IT-04: usuario inexistente devuelve 400 RECUPERACION_INVALIDA")
    void usuarioInexistente_400RECUPERACION_INVALIDA() throws Exception {
        mockMvc.perform(recuperar("rec_it04_no_existe", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Usuario o clave de recuperación inválidos."))
                .andExpect(jsonPath("$.codigo").value("RECUPERACION_INVALIDA"));
    }

    @Test
    @DisplayName("IT-05: usuario inactivo devuelve el mismo 400 genérico")
    void usuarioInactivo_400RECUPERACION_INVALIDA() throws Exception {
        datos.crearUsuario("rec_it05", "vieja123", false);

        mockMvc.perform(recuperar("rec_it05", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Usuario o clave de recuperación inválidos."))
                .andExpect(jsonPath("$.codigo").value("RECUPERACION_INVALIDA"));
    }

    @Test
    @DisplayName("IT-06 / SEG-04: clave incorrecta devuelve 400 y no cambia la contraseña")
    void claveIncorrecta_400YNoCambiaLaPassword() throws Exception {
        datos.crearUsuario("rec_it06", "vieja123", true);

        mockMvc.perform(recuperar("rec_it06", "clave-mala", "NuevaClave123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("RECUPERACION_INVALIDA"));

        EspUsuario usuario = usuarios.findByUsername("rec_it06");
        assertThat(encoder.matches("vieja123", usuario.getPassword())).isTrue();
        assertThat(encoder.matches("NuevaClave123", usuario.getPassword())).isFalse();
    }

    @Test
    @DisplayName("IT-07: contraseña corta devuelve 400 PASSWORD_INVALIDA")
    void passwordCorta_400PASSWORD_INVALIDA() throws Exception {
        datos.crearUsuario("rec_it07", "vieja123", true);

        mockMvc.perform(recuperar("rec_it07", claveRecuperacion, "Abc12"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("PASSWORD_INVALIDA"));

        assertThat(encoder.matches("vieja123", usuarios.findByUsername("rec_it07").getPassword())).isTrue();
    }

    @Test
    @DisplayName("IT-08: campos obligatorios vacíos devuelven 400 DATOS_INCOMPLETOS")
    void camposVacios_400DATOS_INCOMPLETOS() throws Exception {
        mockMvc.perform(recuperar("", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("DATOS_INCOMPLETOS"));

        mockMvc.perform(recuperar("rec_it08", "", "NuevaClave123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("DATOS_INCOMPLETOS"));
    }

    @Test
    @DisplayName("IT-09: la contraseña se guarda con BCrypt, no en texto plano")
    void passwordGuardadaConBCrypt() throws Exception {
        datos.crearUsuario("rec_it09", "vieja123", true);

        mockMvc.perform(recuperar("rec_it09", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());

        String almacenada = usuarios.findByUsername("rec_it09").getPassword();
        assertThat(almacenada).startsWith("$2");
        assertThat(almacenada).isNotEqualTo("NuevaClave123");
        assertThat(encoder.matches("NuevaClave123", almacenada)).isTrue();
    }

    @Test
    @DisplayName("IT-10: la recuperación limpia el cambio de contraseña pendiente")
    void recuperacionExitosa_limpiaRequiereCambioPassword() throws Exception {
        EspUsuario usuario = datos.crearUsuario("rec_it10", "vieja123", true);
        usuario.setRequiereCambioPassword(true);
        usuarios.save(usuario);

        mockMvc.perform(recuperar("rec_it10", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());

        assertThat(usuarios.findByUsername("rec_it10").getRequiereCambioPassword()).isFalse();
    }

    @Test
    @DisplayName("IT-11: la respuesta de una recuperación exitosa no incluye token")
    void respuestaSinToken() throws Exception {
        datos.crearUsuario("rec_it11", "vieja123", true);

        mockMvc.perform(recuperar("rec_it11", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").doesNotExist())
                .andExpect(jsonPath("$.username").value("rec_it11"));
    }

    // ------------------------------------------------------------------
    // SEG-01..SEG-05, SEG-10: seguridad
    // ------------------------------------------------------------------

    @Test
    @DisplayName("SEG-01: funciona sin encabezado Authorization")
    void sinJwt_funciona() throws Exception {
        datos.crearUsuario("rec_seg01", "vieja123", true);

        mockMvc.perform(recuperar("rec_seg01", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("rec_seg01"));
    }

    @Test
    @DisplayName("SEG-02: un JWT inválido en el header no bloquea la recuperación")
    void conJwtInvalido_funciona() throws Exception {
        datos.crearUsuario("rec_seg02", "vieja123", true);

        mockMvc.perform(recuperar("rec_seg02", claveRecuperacion, "NuevaClave123")
                        .header("Authorization", "Bearer token-roto"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("rec_seg02"));
    }

    @Test
    @DisplayName("SEG-03: la recuperación no depende del estado del JWT, ni siquiera vencido")
    void conJwtVencido_funciona() throws Exception {
        datos.crearUsuario("rec_seg03", "vieja123", true);
        Object expiracionOriginal = ReflectionTestUtils.getField(jwtUtil, "jwtExpiration");
        try {
            ReflectionTestUtils.setField(jwtUtil, "jwtExpiration", -1000L);
            String tokenVencido = jwtUtil.generateToken(detalles.loadUserByUsername("rec_seg03"));

            mockMvc.perform(recuperar("rec_seg03", claveRecuperacion, "NuevaClave123")
                            .header("Authorization", "Bearer " + tokenVencido))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.username").value("rec_seg03"));
        } finally {
            ReflectionTestUtils.setField(jwtUtil, "jwtExpiration", expiracionOriginal);
        }
    }

    @Test
    @DisplayName("SEG-05: usuario inexistente, inactivo y clave incorrecta devuelven el mismo error")
    void losTresCasosInvalidos_devuelvenElMismoError() throws Exception {
        datos.crearUsuario("rec_seg05", "vieja123", false);

        List<String> casos = List.of(
                json("rec_seg05_inexistente", claveRecuperacion, "NuevaClave123"),
                json("rec_seg05", claveRecuperacion, "NuevaClave123"),
                json("rec_seg05_ok", "clave-mala", "NuevaClave123"));

        for (String caso : casos) {
            mockMvc.perform(post("/api/auth/recuperar-password")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(caso))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.error").value("Usuario o clave de recuperación inválidos."))
                    .andExpect(jsonPath("$.codigo").value("RECUPERACION_INVALIDA"));
        }
    }

    @Test
    @DisplayName("SEG-10: un JWT emitido antes del reset sigue válido (sin revocación: limitación de 8 h)")
    void tokenEmitidoAntesDelCambio_sigueSiendoValido() throws Exception {
        datos.crearUsuario("rec_seg10", "vieja123", true);

        MvcResult loginResult = mockMvc.perform(login("rec_seg10", "vieja123"))
                .andExpect(status().isOk())
                .andReturn();
        String tokenViejo = JsonPath.read(loginResult.getResponse().getContentAsString(), "$.token");

        mockMvc.perform(recuperar("rec_seg10", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());

        // Documentado: no hay revocación de JWT; el token anterior sigue válido.
        mockMvc.perform(get("/api/productos").header("Authorization", "Bearer " + tokenViejo))
                .andExpect(status().isOk());
    }

    // ------------------------------------------------------------------
    // RL-01..RL-06: límite de intentos
    // ------------------------------------------------------------------

    @Test
    @DisplayName("RL-01: el primer fallo devuelve 400")
    void primerFallo_400() throws Exception {
        datos.crearUsuario("rec_rl01", "vieja123", true);

        mockMvc.perform(recuperar("rec_rl01", "clave-mala", "NuevaClave123"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("RL-02 / RL-03: cinco fallos bloquean; el sexto devuelve 429 incluso con la clave correcta")
    void sextoIntento_429InclusoConClaveCorrecta() throws Exception {
        datos.crearUsuario("rec_rl03", "vieja123", true);

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(recuperar("rec_rl03", "clave-mala-" + i, "NuevaClave123"))
                    .andExpect(status().isBadRequest());
        }

        mockMvc.perform(recuperar("rec_rl03", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.codigo").value("DEMASIADOS_INTENTOS"));
    }

    @Test
    @DisplayName("RL-04: los fallos de un usuario no bloquean a otro")
    void fallosDeUnUsuario_noBloqueanAOtro() throws Exception {
        datos.crearUsuario("rec_rl04_bloqueado", "vieja123", true);
        datos.crearUsuario("rec_rl04_inocente", "vieja123", true);

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(recuperar("rec_rl04_bloqueado", "clave-mala-" + i, "NuevaClave123"))
                    .andExpect(status().isBadRequest());
        }

        mockMvc.perform(recuperar("rec_rl04_inocente", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("RL-05: los fallos de recuperación no bloquean el login correcto")
    void fallosDeRecuperacion_noBloqueanLogin() throws Exception {
        datos.crearUsuario("rec_rl05", "vieja123", true);

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(recuperar("rec_rl05", "clave-mala-" + i, "NuevaClave123"))
                    .andExpect(status().isBadRequest());
        }

        mockMvc.perform(login("rec_rl05", "vieja123")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("RL-06: los fallos de login no bloquean la recuperación correcta")
    void fallosDeLogin_noBloqueanRecuperacion() throws Exception {
        datos.crearUsuario("rec_rl06", "vieja123", true);

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(login("rec_rl06", "mala-" + i)).andExpect(status().isUnauthorized());
        }

        mockMvc.perform(recuperar("rec_rl06", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isOk());

        // Además, la recuperación limpia el contador de login.
        mockMvc.perform(login("rec_rl06", "NuevaClave123")).andExpect(status().isOk());
    }

    // ------------------------------------------------------------------
    // VAL-01..VAL-12: validación de datos
    // ------------------------------------------------------------------

    @Test
    @DisplayName("VAL-01: username vacío devuelve 400")
    void usernameVacio_400() throws Exception {
        mockMvc.perform(recuperar("", claveRecuperacion, "NuevaClave123"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("VAL-02: clave de recuperación vacía devuelve 400")
    void claveVacia_400() throws Exception {
        mockMvc.perform(recuperar("rec_val02", "", "NuevaClave123"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("VAL-03: contraseña vacía devuelve 400")
    void passwordVacia_400() throws Exception {
        datos.crearUsuario("rec_val03", "vieja123", true);

        mockMvc.perform(recuperar("rec_val03", claveRecuperacion, ""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("PASSWORD_INVALIDA"));
    }

    @Test
    @DisplayName("VAL-04: contraseña de cinco caracteres devuelve 400")
    void password5Chars_400() throws Exception {
        datos.crearUsuario("rec_val04", "vieja123", true);

        mockMvc.perform(recuperar("rec_val04", claveRecuperacion, "Abc12"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("PASSWORD_INVALIDA"));
    }

    @Test
    @DisplayName("VAL-05: una contraseña de seis caracteres pasa la validación de longitud")
    void password6Chars_200() throws Exception {
        datos.crearUsuario("rec_val05", "vieja123", true);

        mockMvc.perform(recuperar("rec_val05", claveRecuperacion, "Abc123"))
                .andExpect(status().isOk());

        mockMvc.perform(login("rec_val05", "Abc123")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("VAL-06: los espacios externos de los tres campos se normalizan con trim()")
    void camposConEspacios_seNormalizan() throws Exception {
        datos.crearUsuario("rec_val06", "vieja123", true);

        mockMvc.perform(recuperar("  rec_val06  ", "  " + claveRecuperacion + "  ", "  NuevaClave123  "))
                .andExpect(status().isOk());

        // La contraseña queda trimeda: loguea sin espacios.
        mockMvc.perform(login("rec_val06", "NuevaClave123")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("VAL-07: campos ausentes devuelven error controlado, sin 500")
    void camposAusentes_400() throws Exception {
        mockMvc.perform(post("/api/auth/recuperar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("VAL-08: JSON malformado devuelve error controlado")
    void jsonMalformado_400() throws Exception {
        mockMvc.perform(post("/api/auth/recuperar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("VAL-09: un tipo incorrecto en username devuelve error de validación controlado")
    void tipoIncorrecto_400() throws Exception {
        mockMvc.perform(post("/api/auth/recuperar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": {\"x\": 1}, \"claveRecuperacion\": \"c\", \"passwordNueva\": \"Abc123\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("VAL-10: un cuerpo vacío devuelve error HTTP controlado")
    void cuerpoVacio_400() throws Exception {
        mockMvc.perform(post("/api/auth/recuperar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(""))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("VAL-11: una contraseña con símbolos se acepta si cumple las reglas")
    void passwordConSimbolos_200() throws Exception {
        datos.crearUsuario("rec_val11", "vieja123", true);

        mockMvc.perform(recuperar("rec_val11", claveRecuperacion, "Nueva!Clave#2026$"))
                .andExpect(status().isOk());

        mockMvc.perform(login("rec_val11", "Nueva!Clave#2026$")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("VAL-12: una contraseña larga (64 ASCII) se procesa correctamente")
    void passwordLarga_200() throws Exception {
        datos.crearUsuario("rec_val12", "vieja123", true);
        // 64 caracteres ASCII para no chocar con el límite de 72 bytes de BCrypt.
        String larga = "N" + "a".repeat(62) + "9";

        mockMvc.perform(recuperar("rec_val12", claveRecuperacion, larga))
                .andExpect(status().isOk());

        mockMvc.perform(login("rec_val12", larga)).andExpect(status().isOk());
    }
}
