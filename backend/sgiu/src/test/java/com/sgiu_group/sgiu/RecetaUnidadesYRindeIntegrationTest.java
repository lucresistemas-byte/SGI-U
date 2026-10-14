package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.BeforeEach;
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
 * Etapa 2: cada fila de la receta tiene su unidad (de la familia del insumo)
 * y se convierte a unidad base; el costo del elaborado es costo / rinde.
 */
@WithMockUser
class RecetaUnidadesYRindeIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private RecetaRepository recetaRepository;

    private EspProducto harina;
    private EspProducto leche;
    private EspProducto cinta;
    private EspProducto torta;

    @BeforeEach
    void datos() {
        // Harina comprada por kilo ($1200 el kg = $1,2 el g), leche por litro
        // ($1500 el l = $1,5 el ml), cinta por metro ($200 el m = $2 el cm).
        harina = datos.crearMateriaPrima("RUR-HAR", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 10, 0);
        leche = datos.crearMateriaPrima("RUR-LEC", "Leche", new BigDecimal("1500"), UnidadMedida.LITRO, 5, 0);
        cinta = datos.crearMateriaPrima("RUR-CIN", "Cinta", new BigDecimal("200"), UnidadMedida.METRO, 10, 0);
        torta = datos.crearElaborado("RUR-TORTA", "Porción de torta", new BigDecimal("100"), 0, true);
        torta.setPorcentajeGanancia(new BigDecimal("100"));
        productoRepository.save(torta);
    }

    private static String fila(EspProducto mp, String cantidad, String unidad) {
        return "{\"articuloId\": " + mp.getId() + ", \"cantidad\": " + cantidad
                + (unidad != null ? ", \"unidadMedida\": \"" + unidad + "\"" : "") + "}";
    }

    private ResultActions crear(String rinde, String... filas) throws Exception {
        return mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                .content("{\"espProductoCodigo\": \"RUR-TORTA\", \"nombre\": \"Torta\", "
                        + (rinde != null ? "\"rinde\": " + rinde + ", " : "")
                        + "\"rindeUnidad\": \"porciones\", \"detalles\": [" + String.join(",", filas) + "]}"));
    }

    @Test
    void unidadesMixtas_costoTotalCostoPorPorcionYPrecio() throws Exception {
        // 200 g de harina ($240) + 150 ml de leche ($225) + 0,5 m de cinta ($100) = $565.
        // Rinde 8 porciones: $70,63 la porción; con 100 % de ganancia, $141,26.
        crear("8", fila(harina, "200", "GRAMO"), fila(leche, "150", "MILILITRO"), fila(cinta, "0.5", "METRO"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.costoTotal").value(565.0))
                .andExpect(jsonPath("$.rinde").value(8.0))
                .andExpect(jsonPath("$.rindeUnidad").value("porciones"))
                .andExpect(jsonPath("$.costoPorUnidad").value(70.63))
                .andExpect(jsonPath("$.porcentajeGanancia").value(100.0))
                .andExpect(jsonPath("$.precioVenta").value(141.26))
                .andExpect(jsonPath("$.detalles[0].cantidadBase").value(200.0))
                .andExpect(jsonPath("$.detalles[0].subtotal").value(240.0))
                .andExpect(jsonPath("$.detalles[1].cantidadBase").value(150.0))
                .andExpect(jsonPath("$.detalles[1].subtotal").value(225.0))
                .andExpect(jsonPath("$.detalles[2].cantidad").value(0.5))
                .andExpect(jsonPath("$.detalles[2].unidadMedida").value("METRO"))
                .andExpect(jsonPath("$.detalles[2].cantidadBase").value(50.0))
                .andExpect(jsonPath("$.detalles[2].unidadBase").value("CENTIMETRO"))
                .andExpect(jsonPath("$.detalles[2].subtotal").value(100.0));

        EspProducto actualizado = productoRepository.findByCodigo("RUR-TORTA").orElseThrow();
        assertThat(actualizado.getPrecioCosto()).isEqualByComparingTo("70.63");
        assertThat(actualizado.getPrecioUnitario()).isEqualByComparingTo("141.26");
    }

    @Test
    void laMismaCantidadEnOtraUnidadDeLaFamilia_cuestaLoMismo() throws Exception {
        crear("1", fila(harina, "0.2", "KILO"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.detalles[0].cantidadBase").value(200.0))
                .andExpect(jsonPath("$.costoTotal").value(240.0));
    }

    @Test
    void sinUnidad_seUsaLaBaseDeLaFamilia() throws Exception {
        crear("1", fila(harina, "200", null))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.detalles[0].unidadMedida").value("GRAMO"))
                .andExpect(jsonPath("$.costoTotal").value(240.0));
    }

    @Test
    void unidadDeOtraFamilia_devuelve400() throws Exception {
        crear("1", fila(harina, "1", "LITRO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "La unidad litro no corresponde a Harina, que se mide en peso (gramo, kilo)."));
        assertThat(recetaRepository.findByProducto(torta)).isEmpty();
    }

    @Test
    void rindeObligatorioYMayorACero() throws Exception {
        crear(null, fila(harina, "200", "GRAMO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Indique el rinde de la receta"));
        crear("0", fila(harina, "200", "GRAMO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El rinde de la receta debe ser mayor a cero"));
    }

    @Test
    void cambiaElCostoDeLaMateriaPrima_seRecalculaCostoYPrecioPorPorcion() throws Exception {
        crear("8", fila(harina, "200", "GRAMO"), fila(leche, "150", "MILILITRO"), fila(cinta, "0.5", "METRO"))
                .andExpect(status().isCreated());

        // La harina sube: bolsa de 25 kg a $40.000 ($1,6 el g): 200 g = $320.
        mockMvc.perform(put("/api/materias-primas/" + harina.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Harina\", \"unidadMedida\": \"KILO\", \"presentacionDescripcion\": \"Bolsa 25 kg\", "
                                + "\"presentacionCantidad\": 25, \"presentacionUnidad\": \"KILO\", \"presentacionPrecio\": 40000}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.costoUnidadBase").value(1.6));

        // $645 / 8 = $80,63 la porción; precio $161,26.
        EspProducto actualizado = productoRepository.findByCodigo("RUR-TORTA").orElseThrow();
        assertThat(actualizado.getPrecioCosto()).isEqualByComparingTo("80.63");
        assertThat(actualizado.getPrecioUnitario()).isEqualByComparingTo("161.26");
    }

    @Test
    void editarElRinde_cambiaElCostoPorUnidad() throws Exception {
        String creada = crear("1", fila(harina, "200", "GRAMO")).andReturn().getResponse().getContentAsString();
        long id = Long.parseLong(creada.replaceAll("^\\{\"id\":(\\d+).*", "$1"));

        mockMvc.perform(put("/api/recetas/" + id).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Torta\", \"rinde\": 24, \"rindeUnidad\": \"alfajores\", \"detalles\": ["
                                + fila(harina, "200", "GRAMO") + "]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rindeUnidad").value("alfajores"))
                .andExpect(jsonPath("$.costoPorUnidad").value(10.0))
                .andExpect(jsonPath("$.precioVenta").value(20.0));
    }
}
