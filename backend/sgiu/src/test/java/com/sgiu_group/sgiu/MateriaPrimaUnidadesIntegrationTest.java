package com.sgiu_group.sgiu;

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
import org.springframework.test.web.servlet.ResultActions;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Etapa 2: la materia prima pertenece a una familia; el costo sale de la
 * presentación de compra y stock y costo se guardan en la unidad base.
 */
@WithMockUser
class MateriaPrimaUnidadesIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MateriaPrimaRepository repository;
    @Autowired
    private RecetaRepository recetaRepository;
    @Autowired
    private TestDataFactory datos;

    private ResultActions crear(String json) throws Exception {
        return mockMvc.perform(post("/api/insumos").contentType(MediaType.APPLICATION_JSON).content(json));
    }

    private static String insumo(String nombre, String unidad, String presentacion, String cantidad,
                                 String unidadPresentacion, String precio, String stock, String stockUnidad) {
        return "{\"nombre\": \"" + nombre + "\", \"unidadMedida\": \"" + unidad + "\", "
                + "\"presentacionDescripcion\": \"" + presentacion + "\", \"presentacionCantidad\": " + cantidad + ", "
                + "\"presentacionUnidad\": \"" + unidadPresentacion + "\", \"presentacionPrecio\": " + precio
                + (stock != null ? ", \"stockActual\": " + stock + ", \"stockUnidad\": \"" + stockUnidad + "\"" : "")
                + "}";
    }

    @Test
    void costoPorUnidadBase_desdeLaPresentacionDeCompra() throws Exception {
        // Bolsa de 25 kg a $30.000 → $1,2000 por gramo ($1200 el kilo).
        crear(insumo("Harina 000", "KILO", "Bolsa 25 kg", "25", "KILO", "30000", "2.5", "KILO"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.familia").value("PESO"))
                .andExpect(jsonPath("$.unidadBase").value("GRAMO"))
                .andExpect(jsonPath("$.costoUnidadBase").value(1.2))
                .andExpect(jsonPath("$.costoUnitario").value(1200.0))
                .andExpect(jsonPath("$.presentacionDescripcion").value("Bolsa 25 kg"))
                .andExpect(jsonPath("$.stockActual").value(2500.0));

        // Docena de huevos a $3.000 → $250 la unidad.
        crear(insumo("Huevos", "UNIDAD", "Maple x 1 docena", "1", "DOCENA", "3000", null, null))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.costoUnidadBase").value(250.0));
        // Rollo de 10 m a $2.000 → $2 el centímetro.
        crear(insumo("Cinta", "METRO", "Rollo 10 m", "10", "METRO", "2000", null, null))
                .andExpect(jsonPath("$.costoUnidadBase").value(2.0));
        // Leche 1 l a $1.500 → $1,5 el mililitro; con 4 decimales.
        crear(insumo("Leche", "LITRO", "Sachet 1 l", "1", "LITRO", "1500", null, null))
                .andExpect(jsonPath("$.costoUnidadBase").value(1.5));
        crear(insumo("Esencia", "MILILITRO", "Frasco 30 ml", "30", "MILILITRO", "1000", null, null))
                .andExpect(jsonPath("$.costoUnidadBase").value(33.3333));
    }

    @Test
    void presentacionOStockDeOtraFamilia_devuelve400() throws Exception {
        crear(insumo("Harina", "KILO", "Bolsa", "1", "LITRO", "1000", null, null))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "La unidad litro no corresponde a Harina, que se mide en peso (gramo, kilo)."));
        crear(insumo("Harina", "KILO", "Bolsa", "1", "KILO", "1000", "2", "METRO"))
                .andExpect(status().isBadRequest());
        crear(insumo("Harina", "CAJA", "Bolsa", "1", "KILO", "1000", null, null))
                .andExpect(status().isBadRequest());
    }

    @Test
    void ajusteDeStock_enCualquierUnidadDeLaFamilia() throws Exception {
        MateriaPrima harina = repository.save(new MateriaPrima("MPU-1", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 1, 0));

        mockMvc.perform(post("/api/insumos/" + harina.getId() + "/ajuste-stock").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": 2.5, \"unidad\": \"KILO\", \"motivo\": \"Compra\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stockActual").value(3500.0));
        mockMvc.perform(post("/api/insumos/" + harina.getId() + "/ajuste-stock").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": -500, \"unidad\": \"GRAMO\", \"motivo\": \"Merma\"}"))
                .andExpect(jsonPath("$.stockActual").value(3000.0));
        mockMvc.perform(post("/api/insumos/" + harina.getId() + "/ajuste-stock").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": 1, \"unidad\": \"LITRO\", \"motivo\": \"x\"}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/insumos/" + harina.getId() + "/ajuste-stock").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": -4, \"unidad\": \"KILO\", \"motivo\": \"x\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "El stock resultante no puede ser negativo (actual: 3 kg, ajuste: -4 kg)."));
    }

    private String editar(String unidad) {
        return insumo("Harina", unidad, "Bolsa", "1", unidad, "1000", null, null);
    }

    @Test
    void cambiarLaUnidadParaMostrar_dentroDeLaFamilia_sePermiteConStock() throws Exception {
        MateriaPrima harina = repository.save(new MateriaPrima("MPU-2", "Harina", new BigDecimal("1000"), UnidadMedida.KILO, 3, 0));

        mockMvc.perform(put("/api/insumos/" + harina.getId()).contentType(MediaType.APPLICATION_JSON).content(editar("GRAMO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.unidadMedida").value("GRAMO"))
                .andExpect(jsonPath("$.stockActual").value(3000.0));
    }

    @Test
    void cambiarDeFamilia_conStockOEnRecetaActiva_devuelve400() throws Exception {
        MateriaPrima conStock = repository.save(new MateriaPrima("MPU-3", "Harina", new BigDecimal("1000"), UnidadMedida.KILO, 3, 0));
        mockMvc.perform(put("/api/insumos/" + conStock.getId()).contentType(MediaType.APPLICATION_JSON).content(editar("LITRO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("No se puede pasar Harina de peso a volumen porque tiene stock "
                        + "(3 kg). Lleve el stock a 0 con un ajuste o cree un insumo nuevo."));

        MateriaPrima enReceta = repository.save(new MateriaPrima("MPU-4", "Harina", new BigDecimal("1000"), UnidadMedida.KILO, 0, 0));
        Receta receta = new Receta(datos.crearElaborado("MPU-T", "Torta", new BigDecimal("100"), 0, true),
                "Torta base", null, BigDecimal.ZERO);
        receta.addDetalle(new RecetaDetalle(receta, enReceta, new BigDecimal("0.2"), UnidadMedida.KILO));
        recetaRepository.save(receta);
        mockMvc.perform(put("/api/insumos/" + enReceta.getId()).contentType(MediaType.APPLICATION_JSON).content(editar("LITRO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("No se puede pasar Harina de peso a volumen porque se usa en "
                        + "recetas activas (Torta base). Lleve el stock a 0 con un ajuste o cree un insumo nuevo."));

        // Sin stock ni recetas, sí se puede.
        MateriaPrima libre = repository.save(new MateriaPrima("MPU-5", "Harina", new BigDecimal("1000"), UnidadMedida.KILO, 0, 0));
        mockMvc.perform(put("/api/insumos/" + libre.getId()).contentType(MediaType.APPLICATION_JSON).content(editar("LITRO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.familia").value("VOLUMEN"));
        assertThat(repository.findById(libre.getId()).orElseThrow().getUnidadMedida()).isEqualTo(UnidadMedida.LITRO);
    }
}
