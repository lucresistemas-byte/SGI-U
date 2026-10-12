package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Corrección 3: categorías se renombran y se desactivan/reactivan (no se eliminan). */
@WithMockUser
class CategoriaEdicionIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private CategoriaRepository categoriaRepository;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private TestDataFactory datos;

    private Categoria categoria(String nombre) {
        return categoriaRepository.save(new Categoria(nombre, null));
    }

    @Test
    void renombrar_devuelve200() throws Exception {
        Categoria tortas = categoria("Tortas");

        mockMvc.perform(put("/api/categorias/" + tortas.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Tortas y tartas\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nombre").value("Tortas y tartas"));
    }

    @Test
    void renombrarConUnNombreDeOtraCategoria_devuelve409() throws Exception {
        Categoria tortas = categoria("Tortas");
        categoria("Bebidas");

        mockMvc.perform(put("/api/categorias/" + tortas.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Bebidas\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("Ya existe una categoría con el nombre: Bebidas"));
    }

    @Test
    void renombrarConElMismoNombre_esValido() throws Exception {
        Categoria tortas = categoria("Tortas");

        mockMvc.perform(put("/api/categorias/" + tortas.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Tortas\", \"descripcion\": \"Tortas de la casa\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.descripcion").value("Tortas de la casa"));
    }

    @Test
    void desactivar_laSacaDeLosFormulariosPeroLosProductosLaConservan() throws Exception {
        Categoria tortas = categoria("Tortas");
        categoria("Bebidas");
        EspProducto tarta = datos.crearElaborado("E-1", "Tarta", new BigDecimal("100"), 0, true);
        tarta.setCategoria(tortas);

        mockMvc.perform(patch("/api/categorias/" + tortas.getId() + "/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"activo\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.activo").value(false));

        mockMvc.perform(get("/api/categorias"))
                .andExpect(jsonPath("$[*].nombre", containsInAnyOrder("Bebidas")));
        mockMvc.perform(get("/api/categorias").param("incluirInactivas", "true"))
                .andExpect(jsonPath("$[*].nombre", containsInAnyOrder("Tortas", "Bebidas")));
        assertThat(productoRepository.findByCodigo("E-1").orElseThrow().getCategoria().getNombre())
                .isEqualTo("Tortas");
    }

    @Test
    void reactivar_laVuelveAOfrecer() throws Exception {
        Categoria tortas = categoria("Tortas");
        tortas.setActivo(false);

        mockMvc.perform(patch("/api/categorias/" + tortas.getId() + "/estado").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"activo\": true}"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/categorias"))
                .andExpect(jsonPath("$[*].nombre", containsInAnyOrder("Tortas")));
    }

    @Test
    void categoriaInexistente_devuelve404() throws Exception {
        mockMvc.perform(put("/api/categorias/999999").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"X\"}"))
                .andExpect(status().isNotFound());
    }
}
