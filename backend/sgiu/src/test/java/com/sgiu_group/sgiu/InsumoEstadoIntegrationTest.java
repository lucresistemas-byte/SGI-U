package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Insumos sin eliminar: se desactivan, se reactivan y se siguen editando (E-8). */
@WithMockUser
class InsumoEstadoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    private EspProducto harina() {
        return datos.crearMateriaPrima(
                "INS-HAR", "Harina", new BigDecimal("1000.00"), UnidadMedida.KILO, 5, 1);
    }

    private String estado(boolean activo) {
        return "{\"activo\": " + activo + "}";
    }

    @Test
    void desactivar_loSacaDelListadoPorDefectoYSeVeConIncluirInactivos() throws Exception {
        EspProducto harina = harina();

        mockMvc.perform(patch("/api/materias-primas/" + harina.getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content(estado(false)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(false));

        mockMvc.perform(get("/api/materias-primas")).andExpect(jsonPath("$.length()").value(0));
        mockMvc.perform(get("/api/materias-primas").param("incluirInactivos", "true"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].activo").value(false));
    }

    @Test
    void unInsumoInactivo_sePuedeVerEditarYReactivar() throws Exception {
        EspProducto harina = harina();
        harina.setActivo(false);

        // Antes: 404 "Insumo no encontrado" para cualquier insumo inactivo.
        mockMvc.perform(get("/api/materias-primas/" + harina.getId())).andExpect(status().isOk());
        mockMvc.perform(put("/api/materias-primas/" + harina.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"codigo\": \"INS-HAR\", \"nombre\": \"Harina 0000\", "
                                + "\"unidadMedida\": \"KILO\", \"presentacionCantidad\": 1, "
                                + "\"presentacionUnidad\": \"KILO\", \"presentacionPrecio\": 1100}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Harina 0000"));

        mockMvc.perform(patch("/api/materias-primas/" + harina.getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content(estado(true)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(true));
    }

    @Test
    void estadoSinValor_devuelve400() throws Exception {
        EspProducto harina = harina();

        mockMvc.perform(patch("/api/materias-primas/" + harina.getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Indique si se activa o desactiva (activo: true/false)."));
    }

    @Test
    void crearRecetaConUnInsumoInactivo_devuelve400() throws Exception {
        EspProducto harina = harina();
        harina.setActivo(false);
        datos.crearElaborado("INS-TORTA", "Torta", new BigDecimal("1000.00"), 0, true);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"INS-TORTA\", \"nombre\": \"Torta\", "
                                + "\"rinde\": 1, \"detalles\": [{\"articuloId\": " + harina.getId()
                                + ", \"cantidad\": 0.2, \"unidadMedida\": \"KILO\"}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Harina está desactivado. Reactívelo para usarlo en una receta."));
    }

    /** R-14: el navegador debe poder hacer PATCH (preflight de CORS). */
    @Test
    void cors_permitePatch() throws Exception {
        mockMvc.perform(options("/api/materias-primas/1/estado")
                        .header("Origin", "http://localhost:8080")
                        .header("Access-Control-Request-Method", "PATCH"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Methods", containsString("PATCH")));
    }
}
