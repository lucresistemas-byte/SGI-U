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

/** Recetas sin eliminar: solo se activan/desactivan y se editan (E-6). */
@WithMockUser
class RecetaEstadoIntegrationTest extends AbstractIntegrationTest {

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
        torta = datos.crearProducto("REC-TORTA", "Torta", new BigDecimal("1000.00"), 0, 0);
        harina = materiaPrimaRepository.save(new MateriaPrima(
                "REC-HAR", "Harina", new BigDecimal("1000.00"), UnidadMedida.KILO, 10, 0));
        Receta receta = new Receta(torta, "Torta base", null, new BigDecimal("100.00"));
        receta.addDetalle(new RecetaDetalle(receta, harina, new BigDecimal("0.200"), UnidadMedida.KILO));
        receta = recetaRepository.save(receta);
        torta.setPrecioCosto(new BigDecimal("300.00"));
        return receta;
    }

    private String estado(boolean activo) {
        return "{\"activo\": " + activo + "}";
    }

    private String recetaJson(String nombre, String cantidadHarina, String adicionales) {
        return "{\"espProductoCodigo\": \"REC-TORTA\", \"nombre\": \"" + nombre + "\", "
                + "\"costosAdicionales\": " + adicionales + ", \"detalles\": [{\"materiaPrimaId\": "
                + harina.getId() + ", \"cantidad\": " + cantidadHarina + ", \"unidadMedida\": \"KILO\"}]}";
    }

    private BigDecimal costoTorta() {
        return productoRepository.findByCodigo("REC-TORTA").orElseThrow().getPrecioCosto();
    }

    @Test
    void desactivar_laOcultaDelListadoPorDefectoYSeVeConIncluirInactivas() throws Exception {
        Receta receta = tortaConReceta();

        mockMvc.perform(patch("/api/recetas/" + receta.getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content(estado(false)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(false));

        mockMvc.perform(get("/api/recetas"))
                .andExpect(jsonPath("$.length()").value(0));
        mockMvc.perform(get("/api/recetas").param("incluirInactivas", "true"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].activo").value(false));
        mockMvc.perform(get("/api/recetas/" + receta.getId()))
                .andExpect(status().isOk());
    }

    @Test
    void delete_yaNoExiste_devuelve405EnJson() throws Exception {
        Receta receta = tortaConReceta();

        mockMvc.perform(delete("/api/recetas/" + receta.getId()))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.error").isString());

        assertThat(recetaRepository.findById(receta.getId()).orElseThrow().isActivo()).isTrue();
    }

    @Test
    void crear_paraProductoConRecetaInactiva_devuelve409ConLaRecetaParaReactivar() throws Exception {
        Receta receta = tortaConReceta();
        receta.setActivo(false);

        // Antes: 409 "El código de producto ya existe." (UNIQUE de la base).
        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(recetaJson("Nueva", "0.300", "0")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.codigo").value("RECETA_INACTIVA_EXISTENTE"))
                .andExpect(jsonPath("$.recetaId").value(receta.getId()))
                .andExpect(jsonPath("$.error").value(
                        "El producto Torta ya tiene una receta desactivada (Torta base). "
                                + "Puede reactivarla y editarla."));
    }

    @Test
    void editarUnaRecetaInactiva_seGuardaPeroNoCambiaElCostoDelProducto() throws Exception {
        Receta receta = tortaConReceta();
        receta.setActivo(false);

        mockMvc.perform(put("/api/recetas/" + receta.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content(recetaJson("Torta v2", "0.500", "0")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Torta v2"))
                .andExpect(jsonPath("$.activo").value(false));

        assertThat(costoTorta()).isEqualByComparingTo("300.00");
    }

    @Test
    void reactivar_recalculaElCostoDelProductoConLaReceta() throws Exception {
        Receta receta = tortaConReceta();
        receta.setActivo(false);
        mockMvc.perform(put("/api/recetas/" + receta.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content(recetaJson("Torta v2", "0.500", "0")))
                .andExpect(status().isOk());

        mockMvc.perform(patch("/api/recetas/" + receta.getId() + "/estado")
                        .contentType(MediaType.APPLICATION_JSON).content(estado(true)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(true));

        assertThat(costoTorta()).isEqualByComparingTo("500.00");
    }

    @Test
    void cambiarCostoDeUnInsumoDeRecetaInactiva_noTocaElProducto() throws Exception {
        Receta receta = tortaConReceta();
        receta.setActivo(false);

        mockMvc.perform(put("/api/insumos/" + harina.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"codigo\": \"REC-HAR\", \"nombre\": \"Harina\", \"costoUnitario\": 2000, "
                                + "\"unidadMedida\": \"KILO\"}"))
                .andExpect(status().isOk());

        assertThat(costoTorta()).isEqualByComparingTo("300.00");
    }

    /** Problema 2: el error nombraba el ID del insumo ("ID de insumo: 4"). */
    @Test
    void crearConUnInsumoRepetido_devuelve400ConElNombreDelInsumo() throws Exception {
        tortaConReceta();
        EspProducto budin = datos.crearProducto("REC-BUDIN", "Budín", new BigDecimal("900.00"), 0, 0);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"" + budin.getCodigo() + "\", \"nombre\": \"Budín\", "
                                + "\"detalles\": [{\"materiaPrimaId\": " + harina.getId() + ", \"cantidad\": 0.2}, "
                                + "{\"materiaPrimaId\": " + harina.getId() + ", \"cantidad\": 0.1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El insumo Harina está dos veces en la receta."));
    }
}
