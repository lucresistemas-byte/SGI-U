package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Parte 2: métodos de pago configurables (Configuración → Métodos de pago). */
@WithMockUser
class MetodoPagoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MetodoPagoRepository repository;

    private MetodoPago metodo(String nombre) {
        return repository.findByNombreIgnoreCase(nombre).orElseThrow();
    }

    @Test
    void listar_losInicialesEnOrdenYEfectivoFijo() throws Exception {
        mockMvc.perform(get("/api/metodos-pago"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nombre").value("Efectivo"))
                .andExpect(jsonPath("$[0].fijo").value(true))
                .andExpect(jsonPath("$[1].nombre").value("Mercado Pago"))
                .andExpect(jsonPath("$[2].nombre").value("Tarjeta"))
                .andExpect(jsonPath("$[3].nombre").value("Transferencia"))
                .andExpect(jsonPath("$[3].fijo").value(false));
    }

    @Test
    void crear_quedaAlFinalYNoAdmiteNombreRepetido() throws Exception {
        mockMvc.perform(post("/api/metodos-pago").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \" Cuenta DNI \"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nombre").value("Cuenta DNI"))
                .andExpect(jsonPath("$.activo").value(true))
                .andExpect(jsonPath("$.orden").value(5));

        mockMvc.perform(post("/api/metodos-pago").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"tarjeta\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("Ya existe el método de pago Tarjeta."));
        mockMvc.perform(post("/api/metodos-pago").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"  \"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void renombrar_yEfectivoNoSePuedeRenombrar() throws Exception {
        mockMvc.perform(put("/api/metodos-pago/" + metodo("Tarjeta").getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Tarjeta de débito\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Tarjeta de débito"));

        mockMvc.perform(put("/api/metodos-pago/" + metodo("Efectivo").getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Billetes\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Efectivo no se puede renombrar."));
        assertThat(repository.findByNombreIgnoreCase("Efectivo")).isPresent();
    }

    @Test
    void desactivar_noSeOfreceYSePuedeReactivar_peroEfectivoNo() throws Exception {
        Long mp = metodo("Mercado Pago").getId();
        mockMvc.perform(patch("/api/metodos-pago/" + mp + "/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"activo\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(false));

        mockMvc.perform(get("/api/metodos-pago"))
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[?(@.nombre == 'Mercado Pago')]").isEmpty());
        mockMvc.perform(get("/api/metodos-pago").param("incluirInactivos", "true"))
                .andExpect(jsonPath("$.length()").value(4));

        mockMvc.perform(patch("/api/metodos-pago/" + mp + "/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"activo\": true}"))
                .andExpect(jsonPath("$.activo").value(true));

        mockMvc.perform(patch("/api/metodos-pago/" + metodo("Efectivo").getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"activo\": false}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Efectivo no se puede desactivar."));
        assertThat(metodo("Efectivo").isActivo()).isTrue();
    }

    @Test
    void reordenar_cambiaElOrdenOfrecido() throws Exception {
        Long ef = metodo("Efectivo").getId(), mp = metodo("Mercado Pago").getId(),
                ta = metodo("Tarjeta").getId(), tr = metodo("Transferencia").getId();

        mockMvc.perform(put("/api/metodos-pago/orden").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"ids\": [" + tr + "," + ef + "," + ta + "," + mp + "]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nombre").value("Transferencia"))
                .andExpect(jsonPath("$[3].nombre").value("Mercado Pago"));

        mockMvc.perform(put("/api/metodos-pago/orden").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"ids\": [" + tr + "," + ef + "]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Para reordenar envíe todos los métodos de pago, una vez cada uno."));
    }

    @Test
    void noHayBorradoFisico() throws Exception {
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .delete("/api/metodos-pago/" + metodo("Tarjeta").getId()))
                .andExpect(status().isMethodNotAllowed());
    }
}
