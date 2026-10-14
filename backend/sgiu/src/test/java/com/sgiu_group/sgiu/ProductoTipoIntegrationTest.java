package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Etapa 1: el tipo de artículo decide qué se crea en Productos y qué ve el POS. */
@WithMockUser
class ProductoTipoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    private String producto(String codigo, String tipo) {
        return "{\"codigo\": \"" + codigo + "\", \"nombre\": \"Coca-Cola\", \"precioUnitario\": 1500"
                + (tipo != null ? ", \"tipo\": \"" + tipo + "\"" : "") + "}";
    }

    @Test
    void crearSinTipo_devuelve400() throws Exception {
        mockMvc.perform(post("/api/productos/crear").contentType(MediaType.APPLICATION_JSON)
                        .content(producto("T-1", null)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El tipo de producto es obligatorio."));
    }

    @Test
    void crearReventa_devuelve201ConTipoYVendible() throws Exception {
        mockMvc.perform(post("/api/productos/crear").contentType(MediaType.APPLICATION_JSON)
                        .content(producto("T-2", "REVENTA")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tipo").value("REVENTA"))
                .andExpect(jsonPath("$.vendible").value(true));
    }

    @Test
    void crearElaboradoDesdeProductos_devuelve400() throws Exception {
        mockMvc.perform(post("/api/productos/crear").contentType(MediaType.APPLICATION_JSON)
                        .content(producto("T-3", "ELABORADO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Los productos elaborados se crean desde Recetas."));
    }

    @Test
    void crearTiposDeEtapasSiguientes_devuelve400() throws Exception {
        mockMvc.perform(post("/api/productos/crear").contentType(MediaType.APPLICATION_JSON)
                        .content(producto("T-4", "PAQUETE")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Los paquetes se crean desde Recetas y paquetes."));
        mockMvc.perform(post("/api/productos/crear").contentType(MediaType.APPLICATION_JSON)
                        .content(producto("T-5", "OTRO")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Tipo de producto no válido: OTRO"));
    }

    @Test
    void listar_filtraPorVendibleYPorTipo() throws Exception {
        datos.crearProducto("R-1", "Coca-Cola", new BigDecimal("1500"), 5, 0);
        datos.crearElaborado("E-1", "Tarta de coco", new BigDecimal("10800"), 2, true);
        datos.crearElaborado("E-2", "Ganache", new BigDecimal("4700"), 0, false);

        mockMvc.perform(get("/api/productos"))
                .andExpect(jsonPath("$[*].codigo", containsInAnyOrder("R-1", "E-1", "E-2")));
        mockMvc.perform(get("/api/productos").param("vendible", "true"))
                .andExpect(jsonPath("$[*].codigo", containsInAnyOrder("R-1", "E-1")));
        mockMvc.perform(get("/api/productos").param("tipo", "ELABORADO"))
                .andExpect(jsonPath("$[*].codigo", containsInAnyOrder("E-1", "E-2")))
                .andExpect(jsonPath("$[?(@.codigo == 'E-2')].vendible").value(false));
    }

    @Test
    void editar_preparacionBaseSoloEnElaboradosYElTipoNoCambia() throws Exception {
        datos.crearProducto("R-1", "Coca-Cola", new BigDecimal("1500"), 5, 0);
        datos.crearElaborado("E-1", "Ganache", new BigDecimal("4700"), 0, true);

        mockMvc.perform(put("/api/productos/editar/E-1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"vendible\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.vendible").value(false));
        mockMvc.perform(put("/api/productos/editar/R-1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"vendible\": false}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Solo un producto elaborado puede ser preparación base."));
        mockMvc.perform(put("/api/productos/editar/R-1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tipo\": \"ELABORADO\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El tipo de un producto no se puede cambiar."));
    }
}
