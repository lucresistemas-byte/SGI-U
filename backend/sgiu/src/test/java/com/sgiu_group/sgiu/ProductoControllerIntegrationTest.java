package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WithMockUser
class ProductoControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;

    private String body(ProductoRequestDTO dto) throws Exception {
        return objectMapper.writeValueAsString(dto);
    }

    @Test
    void listar_catalogoVacio_devuelveListaVacia() throws Exception {
        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void listar_conProductos_devuelveCatalogoCompleto() throws Exception {
        datos.crearProducto("CAT-A", "Producto A", new BigDecimal("12.50"), 8, 3);

        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].codigo").value("CAT-A"))
                .andExpect(jsonPath("$[0].nombre").value("Producto A"))
                .andExpect(jsonPath("$[0].precioUnitario").isNumber())
                .andExpect(jsonPath("$[0].stockActual").value(8))
                .andExpect(jsonPath("$[0].stockMinimo").value(3))
                .andExpect(jsonPath("$[0].activo").value(true));
    }

    @Test
    void crear_valido_devuelve201YPersisteProductoYStock() throws Exception {
        ProductoRequestDTO dto = new ProductoRequestDTO(
                "NEW-1", "Nuevo", new BigDecimal("20.00"), 10L, 2, true);

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("NEW-1"))
                .andExpect(jsonPath("$.stockActual").value(10));

        assertThat(productoRepository.findByCodigo("NEW-1")).isPresent();
        assertThat(stockRepository.findByEspProducto_Codigo("NEW-1"))
                .get().extracting("cantidad").isEqualTo(10);
    }

    @Test
    void crear_codigoDuplicado_devuelve409() throws Exception {
        datos.crearProducto("DUP-1", "Existente", new BigDecimal("5.00"), 1, 0);
        ProductoRequestDTO dto = new ProductoRequestDTO(
                "DUP-1", "Duplicado", new BigDecimal("6.00"), 1L, 0, true);

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("El código de producto ya existe."));
    }

    @Test
    void crear_sinPrecio_devuelve422() throws Exception {
        ProductoRequestDTO dto = new ProductoRequestDTO("NO-P", "Sin Precio", null, 1L, 0, true);

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error").value("El precio es obligatorio."));
    }

    @Test
    void crear_stockNegativo_devuelve400PorValidacion() throws Exception {
        ProductoRequestDTO dto = new ProductoRequestDTO(
                "STK-N", "Stock Negativo", new BigDecimal("10.00"), -1L, 0, true);

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El stock no puede ser negativo."));
    }

    @Test
    void crear_precioCero_devuelve400PorValidacion() throws Exception {
        ProductoRequestDTO dto = new ProductoRequestDTO(
                "PRC-0", "Precio Cero", new BigDecimal("0.00"), 1L, 0, true);

        mockMvc.perform(post("/api/productos/crear")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El precio debe ser un valor mayor a $0."));
    }

    @Test
    void editar_productoExistente_devuelve200YActualiza() throws Exception {
        datos.crearProducto("EDI-1", "Viejo", new BigDecimal("10.00"), 5, 1);
        ProductoRequestDTO dto = new ProductoRequestDTO(
                "EDI-1", "Nuevo Nombre", new BigDecimal("15.00"), null, 4, true);

        mockMvc.perform(put("/api/productos/editar/EDI-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Nuevo Nombre"))
                .andExpect(jsonPath("$.precioUnitario").isNumber());

        assertThat(productoRepository.findByCodigo("EDI-1").orElseThrow().getNombre())
                .isEqualTo("Nuevo Nombre");
    }

    @Test
    void editar_productoInexistente_devuelve404() throws Exception {
        ProductoRequestDTO dto = new ProductoRequestDTO("GHOST", "X", new BigDecimal("9.00"), null, null, true);

        mockMvc.perform(put("/api/productos/editar/GHOST")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("No se encontró un producto con el código: GHOST"));
    }

    @Test
    void ajustarStock_valido_devuelve200YModificaStock() throws Exception {
        datos.crearProducto("STK-1", "Con Stock", new BigDecimal("8.00"), 5, 2);

        mockMvc.perform(put("/api/productos/stock/STK-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": 3, \"motivo\": \"reposición\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stockActual").value(8));

        assertThat(stockRepository.findByEspProducto_Codigo("STK-1").orElseThrow().getCantidad())
                .isEqualTo(8);
    }

    @Test
    void ajustarStock_resultadoNegativo_devuelve422() throws Exception {
        datos.crearProducto("STK-2", "Poco Stock", new BigDecimal("8.00"), 2, 1);

        mockMvc.perform(put("/api/productos/stock/STK-2")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": -5, \"motivo\": \"ajuste\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error").value("El stock no puede quedar negativo."));
    }
}