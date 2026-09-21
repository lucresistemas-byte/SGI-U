package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
public class CategoriaControllerTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private CategoriaRepository categoriaRepository;

    @Autowired
    private EspProductoRepository productoRepository;

    @Autowired
    private ArticuloStockRepository stockRepository;

    @BeforeEach
    void setup() {
        limpiarBaseDatos();
    }

    @Test
    @WithMockUser
    void listarCategoriasYCrearSinDuplicados() throws Exception {
        mockMvc.perform(post("/api/categorias")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\":\"Lacteos\",\"descripcion\":\"Leches y yogures\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.nombre").value("Lacteos"));

        // Intento duplicado -> 409 Conflict
        mockMvc.perform(post("/api/categorias")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\":\"Lacteos\",\"descripcion\":\"Duplicado\"}"))
                .andExpect(status().isConflict());

        // Listar categorías
        mockMvc.perform(get("/api/categorias"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nombre").value("Lacteos"));
    }

    @Test
    @WithMockUser
    void filtrarProductosPorCategoria() throws Exception {
        Categoria catBebidas = categoriaRepository.save(new Categoria("Bebidas"));
        Categoria catComidas = categoriaRepository.save(new Categoria("Comidas"));

        EspProducto p1 = new EspProducto("P-BEB", "Agua", new BigDecimal("100.00"));
        p1.setCategoria(catBebidas);
        p1 = productoRepository.save(p1);
        stockRepository.save(new ArticuloStock(p1, 10));

        EspProducto p2 = new EspProducto("P-COM", "Pizza", new BigDecimal("500.00"));
        p2.setCategoria(catComidas);
        p2 = productoRepository.save(p2);
        stockRepository.save(new ArticuloStock(p2, 5));

        // Filtrar por Bebidas
        mockMvc.perform(get("/api/productos").param("categoria", "Bebidas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].codigo").value("P-BEB"));
    }
}
