package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * IT-12: si falla el guardado de la nueva contraseña, no se informa una
 * recuperación exitosa. Clase separada para no contaminar el contexto de los
 * demás tests de integración.
 */
class PasswordRecoveryPersistenceFailureTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    @MockitoSpyBean
    private EspUsuarioRepository usuarios;

    @Value("${sgiu.recovery.key}")
    private String claveRecuperacion;

    @Test
    @DisplayName("IT-12: un fallo de persistencia responde 500 ERROR_INTERNO, nunca un éxito")
    void falloDePersistencia_noDevuelve200() throws Exception {
        datos.crearUsuario("rec_it12", "vieja123", true);

        doThrow(new DataAccessResourceFailureException("fallo simulado de base de datos"))
                .when(usuarios)
                .save(any(EspUsuario.class));

        mockMvc.perform(post("/api/auth/recuperar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"rec_it12\", \"claveRecuperacion\": \"" + claveRecuperacion
                                + "\", \"passwordNueva\": \"NuevaClave123\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.codigo").value("ERROR_INTERNO"));
    }
}
