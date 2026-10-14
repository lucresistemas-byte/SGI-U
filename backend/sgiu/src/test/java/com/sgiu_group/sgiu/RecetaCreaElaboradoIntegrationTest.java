package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Etapa 1 (Punto 5): crear la receta crea el producto elaborado; solo los elaborados tienen receta. */
@WithMockUser
class RecetaCreaElaboradoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;
    @Autowired
    private CategoriaRepository categoriaRepository;

    private EspProducto harina;
    private Categoria tortas;

    @BeforeEach
    void insumos() {
        harina = datos.crearMateriaPrima(
                "RCE-HAR", "Harina", new BigDecimal("1000.00"), UnidadMedida.KILO, 10, 0);
        tortas = categoriaRepository.save(new Categoria("RCE Tortas"));
    }

    /** Producto nuevo con la categoría obligatoria. */
    private String nuevo(String campos) {
        return "{" + campos + ", \"categoriaId\": " + tortas.getId() + "}";
    }

    /** Receta de 0,2 kg de harina ($200) + $100 adicionales = costo $300. */
    private String detalles(boolean repetido) {
        String d = "{\"articuloId\": " + harina.getId() + ", \"cantidad\": 0.2, \"unidadMedida\": \"KILO\"}";
        return "[" + d + (repetido ? ", " + d : "") + "]";
    }

    private String conProductoNuevo(String productoNuevo, boolean repetido) {
        return "{\"nombre\": \"Tarta base\", \"costosAdicionales\": 100, \"productoNuevo\": " + productoNuevo
                + ", \"rinde\": 1, \"detalles\": " + detalles(repetido) + "}";
    }

    @Test
    void conProductoNuevo_creaElElaboradoConCodigoGeneradoStockCeroYPrecio() throws Exception {
        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo(nuevo("\"nombre\": \"Tarta de coco\", \"porcentajeGanancia\": 100"), false)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.espProductoCodigo").value("ELA-0001"))
                .andExpect(jsonPath("$.espProductoNombre").value("Tarta de coco"))
                .andExpect(jsonPath("$.costoTotal").value(300.00));

        EspProducto tarta = productoRepository.findByCodigo("ELA-0001").orElseThrow();
        assertThat(tarta.getTipo()).isEqualTo(TipoArticulo.ELABORADO);
        assertThat(tarta.isVendible()).isTrue();
        assertThat(tarta.getPrecioCosto()).isEqualByComparingTo("300.00");
        assertThat(tarta.getPrecioUnitario()).isEqualByComparingTo("600.00");
        assertThat(stockRepository.findByEspProducto_Codigo("ELA-0001").orElseThrow().getCantidad()).isZero();
        assertThat(tarta.getCategoria().getId()).isEqualTo(tortas.getId());
    }

    @Test
    void conProductoNuevo_sinCategoria_devuelve400YNoCreaNada() throws Exception {
        long antes = productoRepository.count();

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo("{\"nombre\": \"Tarta de coco\"}", false)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Elija una categoría para el producto nuevo."));

        assertThat(productoRepository.count()).isEqualTo(antes);
    }

    @Test
    void conProductoNuevo_conCategoriaInactivaOInexistente_devuelve400() throws Exception {
        tortas.setActivo(false);
        categoriaRepository.save(tortas);
        String mensaje = "La categoría elegida no existe o está desactivada.";

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo(nuevo("\"nombre\": \"Tarta de coco\""), false)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo("{\"nombre\": \"Tarta\", \"categoriaId\": 999999}", false)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
    }

    @Test
    void codigoGenerado_saltaLosQueYaExisten() throws Exception {
        datos.crearElaborado("ELA-0001", "Otro", new BigDecimal("100"), 0, true);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo(nuevo("\"nombre\": \"Tarta de coco\""), false)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.espProductoCodigo").value("ELA-0002"));
    }

    @Test
    void conProductoNuevo_codigoEnviadoSeIgnoraYPreparacionBase() throws Exception {
        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo(nuevo("\"codigo\": \"GAN-1\", \"nombre\": \"Ganache\", \"vendible\": false"), false)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.espProductoCodigo").value("ELA-0001"));

        assertThat(productoRepository.findByCodigo("GAN-1")).isEmpty();
        assertThat(productoRepository.findByCodigo("ELA-0001").orElseThrow().esPreparacionBase()).isTrue();
    }

    @Test
    void conProductoNuevo_siLaRecetaEsInvalida_noCreaElProducto() throws Exception {
        long antes = productoRepository.count();

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content(conProductoNuevo(nuevo("\"nombre\": \"Tarta de coco\""), true)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Harina está dos veces en la receta."));

        assertThat(productoRepository.count()).isEqualTo(antes);
    }

    @Test
    void paraUnProductoDeReventa_devuelve400() throws Exception {
        datos.crearProducto("COCA", "Coca-Cola", new BigDecimal("1500"), 5, 0);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"COCA\", \"nombre\": \"X\", \"rinde\": 1, \"detalles\": " + detalles(false) + "}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Solo los productos elaborados tienen receta: Coca-Cola es de reventa."));
    }

    @Test
    void conProductoExistenteYNuevoALaVez_oSinNinguno_devuelve400() throws Exception {
        datos.crearElaborado("TARTA", "Tarta", new BigDecimal("100"), 0, true);
        String mensaje = "Indique un producto elaborado existente o los datos de uno nuevo (uno de los dos).";

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"TARTA\", \"productoNuevo\": {\"nombre\": \"Otra\"}, "
                                + "\"nombre\": \"X\", \"rinde\": 1, \"detalles\": " + detalles(false) + "}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"X\", \"rinde\": 1, \"detalles\": " + detalles(false) + "}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
    }

    @Test
    void conElaboradoExistente_sigueFuncionando() throws Exception {
        datos.crearElaborado("TARTA", "Tarta", new BigDecimal("100"), 0, true);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"TARTA\", \"nombre\": \"Tarta base\", \"rinde\": 1, \"detalles\": "
                                + detalles(false) + "}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.espProductoCodigo").value("TARTA"));
    }
}
