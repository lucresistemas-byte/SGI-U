package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
public class ProductoUnidadTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private EspProductoRepository productoRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    @WithMockUser
    void crearProductoConUnidadKiloValida() throws Exception {
        String json = """
                {
                    "codigo": "PROD-KILO",
                    "nombre": "Naranjas",
                    "precioUnitario": 150.00,
                    "unidadMedida": "KILO",
                    "stockActual": 25
                }
                """;

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.unidadMedida").value("KILO"));
    }

    @Test
    @WithMockUser
    void rechazarProductoConUnidadInvalida() throws Exception {
        String json = """
                {
                    "codigo": "PROD-INVALIDO",
                    "nombre": "Producto Invalido",
                    "precioUnitario": 100.00,
                    "unidadMedida": "UNIDAD_INEXISTENTE"
                }
                """;

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().is4xxClientError());

        assertFalse(productoRepository.existsByCodigo("PROD-INVALIDO"));
    }
}
