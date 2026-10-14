package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MateriaPrima;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Recetas (corrección 4): no se eliminan ni se desactivan; lo que se desactiva
 * es el producto elaborado, y la receta sigue visible con "productoActivo".
 */
@WithMockUser
class RecetaIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private MateriaPrimaRepository materiaPrimaRepository;
    @Autowired
    private RecetaRepository recetaRepository;
    @Autowired
    private EspProductoRepository productoRepository;

    private EspProducto torta;
    private MateriaPrima harina;

    /** Torta con receta activa: 0,2 kg de harina a $1000/kg + $100 adicionales = costo 300. */
    private Receta tortaConReceta() {
        torta = datos.crearElaborado("REC-TORTA", "Torta", new BigDecimal("1000.00"), 0, true);
        harina = materiaPrimaRepository.save(new MateriaPrima(
                "REC-HAR", "Harina", new BigDecimal("1000.00"), UnidadMedida.KILO, 10, 0));
        Receta receta = new Receta(torta, "Torta base", null, new BigDecimal("100.00"));
        receta.addDetalle(new RecetaDetalle(receta, harina, new BigDecimal("0.200"), UnidadMedida.KILO));
        receta = recetaRepository.save(receta);
        torta.setPrecioCosto(new BigDecimal("300.00"));
        return receta;
    }

    private String recetaJson(String nombre, String cantidadHarina, String adicionales) {
        return "{\"espProductoCodigo\": \"REC-TORTA\", \"nombre\": \"" + nombre + "\", "
                + "\"costosAdicionales\": " + adicionales + ", \"rinde\": 1, \"detalles\": [{\"materiaPrimaId\": "
                + harina.getId() + ", \"cantidad\": " + cantidadHarina + ", \"unidadMedida\": \"KILO\"}]}";
    }

    private BigDecimal costoTorta() {
        return productoRepository.findByCodigo("REC-TORTA").orElseThrow().getPrecioCosto();
    }

    @Test
    void elEndpointDeEstadoYaNoExiste_devuelve404EnJson() throws Exception {
        Receta receta = tortaConReceta();

        mockMvc.perform(patch("/api/recetas/" + receta.getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"activo\": false}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").isString());
        assertThat(recetaRepository.findById(receta.getId()).orElseThrow().isActivo()).isTrue();
    }

    @Test
    void delete_yaNoExiste_devuelve405EnJson() throws Exception {
        Receta receta = tortaConReceta();

        mockMvc.perform(delete("/api/recetas/" + receta.getId()))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.error").isString());
    }

    @Test
    void conElProductoDesactivado_laRecetaSigueVisibleYLoIndica() throws Exception {
        Receta receta = tortaConReceta();
        mockMvc.perform(get("/api/recetas"))
                .andExpect(jsonPath("$[0].productoActivo").value(true));

        mockMvc.perform(put("/api/productos/editar/REC-TORTA").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"activo\": false}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/recetas"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].espProductoCodigo").value("REC-TORTA"))
                .andExpect(jsonPath("$[0].productoActivo").value(false));
        mockMvc.perform(get("/api/recetas/" + receta.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.productoActivo").value(false));
    }

    @Test
    void crearOtraRecetaParaUnProductoQueYaTiene_devuelve400() throws Exception {
        tortaConReceta();

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(recetaJson("Otra", "0.300", "0")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "El producto Torta ya tiene una receta (Torta base). Edítela en lugar de crear otra."));
    }

    @Test
    void editar_recalculaElCostoDelProducto() throws Exception {
        Receta receta = tortaConReceta();

        mockMvc.perform(put("/api/recetas/" + receta.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content(recetaJson("Torta v2", "0.500", "0")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Torta v2"));

        assertThat(costoTorta()).isEqualByComparingTo("500.00");
    }

    /** Problema 2: el error nombraba el ID del insumo ("ID de insumo: 4"). */
    @Test
    void crearConUnInsumoRepetido_devuelve400ConElNombreDelInsumo() throws Exception {
        tortaConReceta();
        EspProducto budin = datos.crearElaborado("REC-BUDIN", "Budín", new BigDecimal("900.00"), 0, true);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"" + budin.getCodigo() + "\", \"nombre\": \"Budín\", "
                                + "\"rinde\": 1, \"detalles\": [{\"materiaPrimaId\": " + harina.getId() + ", \"cantidad\": 0.2}, "
                                + "{\"materiaPrimaId\": " + harina.getId() + ", \"cantidad\": 0.1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El insumo Harina está dos veces en la receta."));
    }
}
