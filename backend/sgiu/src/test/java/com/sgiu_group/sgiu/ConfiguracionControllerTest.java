package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
public class ConfiguracionControllerTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ConfiguracionNegocioRepository configuracionRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    @WithMockUser
    void obtenerConfiguracionPorDefecto() throws Exception {
        mockMvc.perform(get("/api/configuracion"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").exists())
                .andExpect(jsonPath("$.codigoCliente").exists());
    }

    @Test
    @WithMockUser
    void actualizarConfiguracionParcialmentePreservaDatosPrevios() throws Exception {
        ConfiguracionNegocio inicial = new ConfiguracionNegocio("Almacén Inicial", "SGIU-SANDRA-001");
        inicial.setDireccion("Calle 1");
        inicial.setTelefono("123456");
        inicial.setLogo(new byte[]{1, 2, 3});
        configuracionRepository.save(inicial);

        // Actualización parcial: solo nombre y teléfono, sin enviar logo ni dirección
        String jsonUpdate = """
                {
                    "nombre": "Almacén Modificado",
                    "telefono": "987654"
                }
                """;

        mockMvc.perform(put("/api/configuracion")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonUpdate))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Almacén Modificado"))
                .andExpect(jsonPath("$.telefono").value("987654"))
                .andExpect(jsonPath("$.codigoCliente").value("SGIU-SANDRA-001"))
                .andExpect(jsonPath("$.direccion").value("Calle 1"));

        ConfiguracionNegocio guardada = configuracionRepository.findFirstByOrderByIdAsc().orElse(null);
        assertNotNull(guardada);
        assertNotNull(guardada.getLogo()); // Conserva logo previo
    }
}
