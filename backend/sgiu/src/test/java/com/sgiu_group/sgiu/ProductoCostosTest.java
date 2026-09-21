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
public class ProductoCostosTest extends AbstractIntegrationTest {

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
    void calculoReciprocoCostoYPorcentajeCalculaPrecioVenta() throws Exception {
        // Costo 100 + % 25 -> Precio 125
        String json = """
                {
                    "codigo": "P-RECIP-1",
                    "nombre": "Producto Con Margen",
                    "precioCosto": 100.00,
                    "porcentajeGanancia": 25.00
                }
                """;

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.precioUnitario").value(125.00))
                .andExpect(jsonPath("$.precioCosto").value(100.00))
                .andExpect(jsonPath("$.porcentajeGanancia").value(25.00));
    }

    @Test
    @WithMockUser
    void calculoReciprocoCostoYVentaDerivaPorcentaje() throws Exception {
        // Costo 100 + Venta 125 -> % 25
        String json = """
                {
                    "codigo": "P-RECIP-2",
                    "nombre": "Producto Con Precio",
                    "precioUnitario": 125.00,
                    "precioCosto": 100.00
                }
                """;

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.precioUnitario").value(125.00))
                .andExpect(jsonPath("$.porcentajeGanancia").value(25.00));
    }

    @Test
    @WithMockUser
    void rechazarCostoNegativo() throws Exception {
        String json = """
                {
                    "codigo": "P-NEG",
                    "nombre": "Producto Negativo",
                    "precioUnitario": 100.00,
                    "precioCosto": -5.00
                }
                """;

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json))
                .andExpect(status().is4xxClientError());

        assertFalse(productoRepository.existsByCodigo("P-NEG"));
    }
}
