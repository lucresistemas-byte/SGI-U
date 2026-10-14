package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Etapa 4: paquetes. Precio = costo del armado (insumos) + monto fijo, hacia arriba a $100. */
@WithMockUser
class PaqueteIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    private ResultActions enviar(MockHttpServletRequestBuilder req, String body) throws Exception {
        return mockMvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(body));
    }

    private static String fila(EspProducto a, String cantidad, String unidad) {
        return "{\"articuloId\": " + a.getId() + ", \"cantidad\": " + cantidad + ", \"unidadMedida\": \"" + unidad + "\"}";
    }

    @Test
    void paquete_precioEsArmadoMasFijo_redondeado_yCambiaSiCambiaUnInsumo() throws Exception {
        EspProducto caja = datos.crearArticuloDeMateriaPrima(TipoArticulo.INSUMO, "INS-CJ", "Caja", new BigDecimal("900"),
                UnidadMedida.UNIDAD, 10, 0);
        EspProducto cinta = datos.crearArticuloDeMateriaPrima(TipoArticulo.INSUMO, "INS-CI", "Cinta", new BigDecimal("300"),
                UnidadMedida.METRO, 10, 0);
        EspProducto papel = datos.crearArticuloDeMateriaPrima(TipoArticulo.INSUMO, "INS-PA", "Papel", new BigDecimal("1000"),
                UnidadMedida.METRO, 10, 0);

        String body = "{\"nombre\": \"Paquete día de la madre\", \"montoFijo\": 1550, \"armado\": ["
                + fila(caja, "1", "UNIDAD") + "," + fila(cinta, "1", "METRO") + "," + fila(papel, "100", "CENTIMETRO") + "]}";
        // Armado $900 + $300 + $1.000 = $2.200; + $1.550 = $3.750 → $3.800.
        enviar(post("/api/paquetes"), body)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("PAQ-0001"))
                .andExpect(jsonPath("$.costoArmado").value(2200.0))
                .andExpect(jsonPath("$.montoFijo").value(1550.0))
                .andExpect(jsonPath("$.precioVenta").value(3800.0))
                .andExpect(jsonPath("$.gananciaPesos").value(1600.0))
                .andExpect(jsonPath("$.armado[2].subtotal").value(1000.0));

        // Se vende en el POS como un producto más.
        mockMvc.perform(get("/api/productos").param("vendible", "true"))
                .andExpect(jsonPath("$[?(@.codigo == 'PAQ-0001')].precioUnitario").value(3800.0))
                .andExpect(jsonPath("$[?(@.codigo == 'PAQ-0001')].modoPrecio").value("COSTO_MAS_FIJO"));

        // La cinta pasa a $600 el metro: armado $2.500 + $1.550 = $4.050 → $4.100.
        enviar(put("/api/materias-primas/" + cinta.getId()),
                "{\"nombre\": \"Cinta\", \"unidadMedida\": \"METRO\", \"presentacionCantidad\": 1, "
                        + "\"presentacionUnidad\": \"METRO\", \"presentacionPrecio\": 600}")
                .andExpect(jsonPath("$.cambiosDePrecio[0].codigo").value("PAQ-0001"))
                .andExpect(jsonPath("$.cambiosDePrecio[0].precioNuevo").value(4100.0));
    }

    @Test
    void paquete_soloLlevaInsumos() throws Exception {
        EspProducto harina = datos.crearMateriaPrima("MP-HA", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 1, 0);
        enviar(post("/api/paquetes"), "{\"nombre\": \"P\", \"montoFijo\": 0, \"armado\": [" + fila(harina, "1", "KILO") + "]}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Harina no es un insumo: el armado de un paquete lleva insumos (cajas, cintas, papel...)."));
    }

}
