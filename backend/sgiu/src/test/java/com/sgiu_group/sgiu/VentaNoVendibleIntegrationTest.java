package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Etapa 1: solo se vende lo vendible (activo, de tipo vendible, no preparación base). */
@WithMockUser
class VentaNoVendibleIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private VentaRepository ventaRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;

    private String venta(String codigo) {
        return "{\"metodoPago\": 1, \"lineas\": [{\"codigoProducto\": \"" + codigo + "\", \"cantidad\": 1}]}";
    }

    @Test
    void venderUnaPreparacionBase_devuelve400YNoDescuenta() throws Exception {
        datos.crearElaborado("GAN", "Ganache", new BigDecimal("4700"), 3, false);

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON).content(venta("GAN")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Ganache es una preparación base y no se vende."));

        assertThat(ventaRepository.count()).isZero();
        assertThat(stockRepository.findByEspProducto_Codigo("GAN").orElseThrow().getCantidad()).isEqualTo(3);
    }

    @Test
    void venderUnProductoDesactivado_devuelve400() throws Exception {
        EspProducto coca = datos.crearProducto("COCA", "Coca-Cola", new BigDecimal("1500"), 5, 0);
        coca.setActivo(false);

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON).content(venta("COCA")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Coca-Cola está desactivado y no se puede vender."));
    }

    @Test
    void venderUnElaboradoVendible_funciona() throws Exception {
        datos.crearElaborado("TARTA", "Tarta de coco", new BigDecimal("10800"), 2, true);

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON).content(venta("TARTA")))
                .andExpect(status().isCreated());
    }
}
