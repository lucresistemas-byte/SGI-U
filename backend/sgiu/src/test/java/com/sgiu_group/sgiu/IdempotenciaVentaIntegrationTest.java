package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * A2: el token de idempotencia evita ventas duplicadas cuando la red o el
 * reintento de stock repiten la misma petición de cobro.
 */
@WithMockUser
class IdempotenciaVentaIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    @BeforeEach
    void producto() {
        datos.crearProducto("IDEM-1", "Torta Idem", new BigDecimal("500.00"), 10, 0);
    }

    private String cuerpo(String token) {
        return "{\"lineas\": [{\"codigoProducto\": \"IDEM-1\", \"cantidad\": 1}],"
                + " \"tokenIdempotencia\": \"" + token + "\"}";
    }

    @Test
    void repetirElMismoToken_noDuplicaLaVenta() throws Exception {
        String primero = mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpo("token-reintento-001")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andReturn().getResponse().getContentAsString();

        String segundo = mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpo("token-reintento-001")))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        int idPrimero = com.jayway.jsonpath.JsonPath.read(primero, "$.id");
        int idSegundo = com.jayway.jsonpath.JsonPath.read(segundo, "$.id");
        assertThat(idSegundo).isEqualTo(idPrimero);

        assertThat(ventaRepository.count()).isEqualTo(1);
        // El stock solo se descontó una vez (10 - 1 = 9).
        assertThat(articuloStockRepository.findByEspProducto_Codigo("IDEM-1")
                .orElseThrow().getCantidad()).isEqualByComparingTo(new BigDecimal("9"));
    }

    @Test
    void tokensDistintos_generanVentasDistintas() throws Exception {
        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpo("token-venta-A")))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(cuerpo("token-venta-B")))
                .andExpect(status().isCreated());

        assertThat(ventaRepository.count()).isEqualTo(2);
    }

    @Autowired
    private com.sgiu_group.sgiu.repositories.VentaRepository ventaRepository;

    @Autowired
    private com.sgiu_group.sgiu.repositories.ArticuloStockRepository articuloStockRepository;
}
