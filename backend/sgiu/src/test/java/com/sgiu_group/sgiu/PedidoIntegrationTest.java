package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Pedidos: E-14 (cancelar dos veces), E-19 (búsqueda) y E-20 (fecha de entrega). */
@WithMockUser
class PedidoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private ObjectMapper objectMapper;

    private long crear(String nombre, String telefono, String descripcion, String fechaEntrega) throws Exception {
        String body = "{\"clienteNombre\": \"" + nombre + "\", \"clienteTelefono\": \"" + telefono + "\", "
                + "\"descripcion\": \"" + descripcion + "\", \"montoTotal\": 9000, \"senia\": 3000"
                + (fechaEntrega != null ? ", \"fechaEntrega\": \"" + fechaEntrega + "\"" : "") + "}";
        String json = mockMvc.perform(post("/api/pedidos").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        JsonNode nodo = objectMapper.readTree(json);
        return nodo.get("id").asLong();
    }

    // --- E-14 ---

    @Test
    void cancelarUnPedidoYaCancelado_devuelve400() throws Exception {
        long id = crear("Ana", "11-5555-0001", "Torta", null);
        mockMvc.perform(post("/api/pedidos/" + id + "/cancelar")).andExpect(status().isOk());

        // Antes: 200 otra vez, sin avisar.
        mockMvc.perform(post("/api/pedidos/" + id + "/cancelar"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El pedido ya está cancelado."));
    }

    // --- E-19 ---

    @Test
    void buscarPorTelefono_comparaSoloDigitos() throws Exception {
        crear("Ana Pérez", "11-5555-0001", "Torta chocolate", null);
        crear("Bruno", "(011) 4444 2222", "Budín", null);

        // Antes: "1155550001" no encontraba "11-5555-0001".
        mockMvc.perform(get("/api/pedidos").param("q", "1155550001"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].clienteNombre").value("Ana Pérez"));
        mockMvc.perform(get("/api/pedidos").param("q", "4444-2222"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].clienteNombre").value("Bruno"));
    }

    @Test
    void buscar_tambienPorDescripcionYPorNombre() throws Exception {
        crear("Ana Pérez", "11-5555-0001", "Torta chocolate 2 pisos", null);
        crear("Bruno", "11-4444-2222", "Budín de limón", null);

        // Antes: la descripción no se buscaba en el backend.
        mockMvc.perform(get("/api/pedidos").param("q", "CHOCOLATE"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].clienteNombre").value("Ana Pérez"));
        mockMvc.perform(get("/api/pedidos").param("q", "bruno"))
                .andExpect(jsonPath("$.length()").value(1));
    }

    // --- E-20 ---

    @Test
    void crearConFechaDeEntregaPasada_devuelve400() throws Exception {
        String ayer = LocalDateTime.now().minusDays(1).truncatedTo(ChronoUnit.MINUTES).toString();

        mockMvc.perform(post("/api/pedidos").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clienteNombre\": \"Ana\", \"clienteTelefono\": \"1\", "
                                + "\"descripcion\": \"Torta\", \"montoTotal\": 100, \"fechaEntrega\": \"" + ayer + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("La fecha de entrega no puede ser anterior al momento actual."));
    }

    @Test
    void crearConFechaYHoraDeEntregaFutura_laGuarda() throws Exception {
        String manana = LocalDateTime.now().plusDays(1).withHour(15).withMinute(30)
                .truncatedTo(ChronoUnit.MINUTES).toString();
        long id = crear("Ana", "1", "Torta", manana);

        mockMvc.perform(get("/api/pedidos/" + id))
                .andExpect(jsonPath("$.fechaEntrega").value(manana + ":00"));
    }
}
