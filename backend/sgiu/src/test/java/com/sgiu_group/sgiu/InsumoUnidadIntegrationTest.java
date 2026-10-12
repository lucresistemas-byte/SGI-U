package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MateriaPrima;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * E-10: cambiar la unidad de un insumo no convierte su stock ni las recetas
 * (3 kg pasaban a ser "3 g"). Solo se permite sin stock y sin recetas activas.
 */
@WithMockUser
class InsumoUnidadIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MateriaPrimaRepository materiaPrimaRepository;
    @Autowired
    private RecetaRepository recetaRepository;
    @Autowired
    private TestDataFactory datos;

    private MateriaPrima harina(int stock) {
        return materiaPrimaRepository.save(new MateriaPrima(
                "UNI-HAR", "Harina", new BigDecimal("1000.00"), UnidadMedida.KILO, stock, 0));
    }

    private String aGramo() {
        return "{\"codigo\": \"UNI-HAR\", \"nombre\": \"Harina\", \"costoUnitario\": 1000, "
                + "\"unidadMedida\": \"GRAMO\"}";
    }

    @Test
    void cambiarUnidadConStock_devuelve400YNoCambiaNada() throws Exception {
        MateriaPrima harina = harina(3);

        mockMvc.perform(put("/api/insumos/" + harina.getId())
                        .contentType(MediaType.APPLICATION_JSON).content(aGramo()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "No se puede cambiar la unidad de Harina (KILO a GRAMO) porque el stock y las "
                                + "recetas no se convierten: tiene stock (3). Lleve el stock a 0 con un "
                                + "ajuste o cree un insumo nuevo con la otra unidad."));

        assertThat(materiaPrimaRepository.findById(harina.getId()).orElseThrow().getUnidadMedida())
                .isEqualTo(UnidadMedida.KILO);
    }

    @Test
    void cambiarUnidadUsadoEnRecetaActiva_devuelve400ConLasRecetas() throws Exception {
        MateriaPrima harina = harina(0);
        EspProducto torta = datos.crearProducto("UNI-TORTA", "Torta", new BigDecimal("1000.00"), 0, 0);
        Receta receta = new Receta(torta, "Torta base", null, BigDecimal.ZERO);
        receta.addDetalle(new RecetaDetalle(receta, harina, new BigDecimal("0.200"), UnidadMedida.KILO));
        recetaRepository.save(receta);

        mockMvc.perform(put("/api/insumos/" + harina.getId())
                        .contentType(MediaType.APPLICATION_JSON).content(aGramo()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "No se puede cambiar la unidad de Harina (KILO a GRAMO) porque el stock y las "
                                + "recetas no se convierten: se usa en recetas activas (Torta base). "
                                + "Lleve el stock a 0 con un ajuste o cree un insumo nuevo con la otra unidad."));
    }

    @Test
    void cambiarUnidadSinStockNiRecetas_sePermite() throws Exception {
        MateriaPrima harina = harina(0);

        mockMvc.perform(put("/api/insumos/" + harina.getId())
                        .contentType(MediaType.APPLICATION_JSON).content(aGramo()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.unidadMedida").value("GRAMO"));
    }

    @Test
    void editarConLaMismaUnidad_conStock_sigueFuncionando() throws Exception {
        MateriaPrima harina = harina(3);

        mockMvc.perform(put("/api/insumos/" + harina.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"codigo\": \"UNI-HAR\", \"nombre\": \"Harina 0000\", "
                                + "\"costoUnitario\": 1100, \"unidadMedida\": \"kilo\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Harina 0000"));
    }
}
