package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.support.TestDataFactory;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Corrección 9: el sistema genera el código de cada artículo según su tipo. */
@WithMockUser
class CodigoAutomaticoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private com.sgiu_group.sgiu.repositories.EspProductoRepository articulos;

    @Autowired
    private TestDataFactory datos;


    private String insumo(String tipo, String nombre) {
        return "{" + (tipo != null ? "\"tipo\": \"" + tipo + "\", " : "")
                + "\"codigo\": \"MIO-1\", \"nombre\": \"" + nombre + "\", \"unidadMedida\": \"KILO\", "
                + "\"presentacionCantidad\": 1, \"presentacionUnidad\": \"KILO\", \"presentacionPrecio\": 100, "
                + "\"stockActual\": 1, \"stockMinimo\": 0}";
    }

    @Test
    void materiaPrima_elCodigoDependeDelTipoElegido() throws Exception {
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(insumo("MATERIA_PRIMA", "Harina")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("MP-0001"))
                .andExpect(jsonPath("$.tipo").value("MATERIA_PRIMA"));
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(insumo("INSUMO", "Caja")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("INS-0001"))
                .andExpect(jsonPath("$.tipo").value("INSUMO"));
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(insumo("REVENTA_MATERIA_PRIMA", "Chocolate en barra")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("RMP-0001"));
        // Sin tipo: materia prima. El código enviado ("MIO-1") se ignora siempre.
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(insumo(null, "Azúcar")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("MP-0002"));

        assertThat(articulos.existsByCodigo("MIO-1")).isFalse();
        assertThat(articulos.findByCodigo("INS-0001").orElseThrow().getTipo())
                .isEqualTo(TipoArticulo.INSUMO);
    }

    @Test
    void materiaPrima_saltaLosCodigosQueYaExisten() throws Exception {
        datos.crearMateriaPrima(
                "MP-0001", "Cargada antes", new BigDecimal("1"), UnidadMedida.KILO, 0, 0);

        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(insumo("MATERIA_PRIMA", "Harina")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("MP-0002"));
    }

    @Test
    void materiaPrima_tipoDeOtroCatalogo_devuelve400() throws Exception {
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(insumo("ELABORADO", "Torta")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Tipo no válido: ELABORADO. Elija materia prima, insumo o reventa + materia prima."));
    }

    @Test
    void materiaPrima_alEditar_elCodigoYElTipoNoCambian() throws Exception {
        EspProducto mp = datos.crearMateriaPrima(
                "INS-0009", "Cinta", new BigDecimal("1"), UnidadMedida.METRO, 0, 0);
        mp.setTipo(TipoArticulo.INSUMO);
        articulos.save(mp);

        mockMvc.perform(put("/api/materias-primas/" + mp.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content(insumo("MATERIA_PRIMA", "Cinta roja")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.codigo").value("INS-0009"))
                .andExpect(jsonPath("$.tipo").value("INSUMO"))
                .andExpect(jsonPath("$.nombre").value("Cinta roja"));
    }
}
