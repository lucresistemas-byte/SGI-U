package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.ModoPrecio;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.HistorialPrecioRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Etapa 4: motor de precios. Chocolate ($18 el g) y crema ($5,5 el ml) →
 * ganache (preparación base: 400 g + 400 ml, rinde 800 g = $11,75 el g) →
 * torta (300 g de ganache + 100 g de chocolate = $5.325, 100 % → $10.700).
 */
@WithMockUser(username = "sandra")
class MotorDePreciosIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private RecetaRepository recetaRepository;
    @Autowired
    private HistorialPrecioRepository historialRepository;
    @Autowired
    private PlatformTransactionManager transactionManager;
    @Autowired
    private ObjectMapper json;

    private EspProducto chocolate;
    private EspProducto crema;

    private ResultActions enviar(org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder req,
                                 String body) throws Exception {
        return mockMvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(body));
    }

    private static String fila(EspProducto a, String cantidad, String unidad) {
        return "{\"articuloId\": " + a.getId() + ", \"cantidad\": " + cantidad + ", \"unidadMedida\": \"" + unidad + "\"}";
    }

    private ResultActions receta(String codigo, String rinde, String rindeUnidadMedida, String... filas) throws Exception {
        return enviar(post("/api/recetas"), "{\"espProductoCodigo\": \"" + codigo + "\", \"nombre\": \"Receta " + codigo
                + "\", \"rinde\": " + rinde + (rindeUnidadMedida != null ? ", \"rindeUnidadMedida\": \"" + rindeUnidadMedida + "\"" : "")
                + ", \"detalles\": [" + String.join(",", filas) + "]}");
    }

    private ResultActions cambiarPrecioDelChocolate(String precioKilo) throws Exception {
        return enviar(put("/api/materias-primas/" + chocolate.getId()),
                "{\"nombre\": \"Chocolate\", \"unidadMedida\": \"KILO\", \"presentacionCantidad\": 1, "
                        + "\"presentacionUnidad\": \"KILO\", \"presentacionPrecio\": " + precioKilo + "}");
    }

    /** Chocolate, crema, ganache (rinde 800 g) y torta (100 %) con sus recetas. */
    private EspProducto tortaConGanache() throws Exception {
        chocolate = datos.crearMateriaPrima("MP-CH", "Chocolate", new BigDecimal("18000"), UnidadMedida.KILO, 5, 0);
        crema = datos.crearMateriaPrima("MP-CR", "Crema", new BigDecimal("5500"), UnidadMedida.LITRO, 5, 0);
        EspProducto ganache = datos.crearElaborado("ELA-GAN", "Ganache", BigDecimal.ZERO, 0, false);
        receta("ELA-GAN", "800", "GRAMO", fila(chocolate, "400", "GRAMO"), fila(crema, "0.4", "LITRO"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.preparacionBase").value(true))
                .andExpect(jsonPath("$.rindeUnidad").value("g"))
                .andExpect(jsonPath("$.costoTotal").value(9400.0))
                .andExpect(jsonPath("$.costoUnidadBase").value(11.75));

        EspProducto torta = datos.crearElaborado("ELA-TOR", "Torta", BigDecimal.ZERO, 0, true);
        torta.setPorcentajeGanancia(new BigDecimal("100"));
        productoRepository.save(torta);
        receta("ELA-TOR", "1", null, fila(ganache, "300", "GRAMO"), fila(chocolate, "100", "GRAMO"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.detalles[0].articuloTipo").value("ELABORADO"))
                .andExpect(jsonPath("$.detalles[0].subtotal").value(3525.0))
                .andExpect(jsonPath("$.costoPorUnidad").value(5325.0))
                // $10.650 → hacia arriba a $100.
                .andExpect(jsonPath("$.precioVenta").value(10700.0))
                .andExpect(jsonPath("$.gananciaPorUnidad").value(5375.0));
        return productoRepository.findByCodigo("ELA-TOR").orElseThrow();
    }

    @Test
    void propagacionMultinivel_chocolate_ganache_torta_conResumenEHistorial() throws Exception {
        tortaConGanache();

        // Chocolate a $24 el g: ganache (9.600 + 2.200) / 800 = $14,75 el g;
        // torta 300 × 14,75 + 100 × 24 = $6.825 → × 2 = $13.650 → $13.700.
        cambiarPrecioDelChocolate("24000")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cambiosDePrecio.length()").value(1))
                .andExpect(jsonPath("$.cambiosDePrecio[0].codigo").value("ELA-TOR"))
                .andExpect(jsonPath("$.cambiosDePrecio[0].precioAnterior").value(10700.0))
                .andExpect(jsonPath("$.cambiosDePrecio[0].precioNuevo").value(13700.0))
                .andExpect(jsonPath("$.cambiosDePrecio[0].gananciaPesos").value(6875.0));

        EspProducto ganache = productoRepository.findByCodigo("ELA-GAN").orElseThrow();
        assertThat(ganache.getCostoUnidadBase()).isEqualByComparingTo("14.75");
        EspProducto torta = productoRepository.findByCodigo("ELA-TOR").orElseThrow();
        assertThat(torta.getPrecioCosto()).isEqualByComparingTo("6825");
        assertThat(torta.getPrecioUnitario()).isEqualByComparingTo("13700");

        // Historial del cambio: chocolate, ganache y torta, una vez cada uno, con la causa y el usuario.
        assertThat(historialRepository.findAll().stream()
                .filter(h -> h.getCausa().equals("Cambio en Chocolate (MP-CH)"))
                .map(h -> h.getArticulo().getCodigo()))
                .containsExactlyInAnyOrder("MP-CH", "ELA-GAN", "ELA-TOR");
        mockMvc.perform(get("/api/precios/historial").param("codigo", "ELA-TOR"))
                // El más reciente primero (antes: el alta de su receta, de $0 a $10.700).
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].precioAnterior").value(10700.0))
                .andExpect(jsonPath("$[0].precioNuevo").value(13700.0))
                .andExpect(jsonPath("$[0].causa").value("Cambio en Chocolate (MP-CH)"))
                .andExpect(jsonPath("$[0].usuario").value("sandra"))
                .andExpect(jsonPath("$[0].modoPrecio").value("MARGEN"));
    }

    @Test
    void precioAMano_seConservaSiDejaElPorcentaje_ySubeAlMinimoSiNo() throws Exception {
        tortaConGanache();

        enviar(put("/api/productos/editar/ELA-TOR"), "{\"precioUnitario\": 15000, \"modoPrecio\": \"MANUAL\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.precioUnitario").value(15000.0))
                .andExpect(jsonPath("$.modoPrecio").value("MANUAL"))
                .andExpect(jsonPath("$.gananciaPesos").value(9675.0));

        // El mínimo sube a $13.700: el precio a mano ($15.000) se conserva.
        cambiarPrecioDelChocolate("24000").andExpect(jsonPath("$.cambiosDePrecio.length()").value(0));
        assertThat(productoRepository.findByCodigo("ELA-TOR").orElseThrow().getPrecioUnitario())
                .isEqualByComparingTo("15000");

        // Chocolate a $40 el g: torta $10.825 × 2 = $21.650 → sube sola a $21.700 (sigue MANUAL).
        cambiarPrecioDelChocolate("40000")
                .andExpect(jsonPath("$.cambiosDePrecio[0].precioAnterior").value(15000.0))
                .andExpect(jsonPath("$.cambiosDePrecio[0].precioNuevo").value(21700.0));
        EspProducto torta = productoRepository.findByCodigo("ELA-TOR").orElseThrow();
        assertThat(torta.getPrecioUnitario()).isEqualByComparingTo("21700");
        assertThat(torta.getModoPrecio()).isEqualTo(ModoPrecio.MANUAL);
    }

    @Test
    void precioAMano_porDebajoDelPorcentaje_seRechaza() throws Exception {
        tortaConGanache();

        enviar(put("/api/productos/editar/ELA-TOR"), "{\"precioUnitario\": 5000, \"modoPrecio\": \"MANUAL\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "El precio $5000.00 deja menos del 100 % de ganancia de Torta: el mínimo es $10700.00."));
    }

    @Test
    void reventaConPrecioAMano_subeAlMinimoSiSubeElCosto() throws Exception {
        enviar(post("/api/productos/crear"), "{\"tipo\": \"REVENTA\", \"nombre\": \"Bombones\", \"precioCosto\": 1000, "
                + "\"porcentajeGanancia\": 50, \"precioUnitario\": 2000, \"modoPrecio\": \"MANUAL\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.precioUnitario").value(2000.0))
                .andExpect(jsonPath("$.gananciaPesos").value(1000.0));

        // Costo $1.500: mínimo 1.500 × 1,5 = $2.250 → $2.300.
        enviar(put("/api/productos/editar/REV-0001"), "{\"precioCosto\": 1500}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.precioUnitario").value(2300.0))
                .andExpect(jsonPath("$.modoPrecio").value("MANUAL"))
                .andExpect(jsonPath("$.cambiosDePrecio[0].precioNuevo").value(2300.0));

        // Vuelve a seguir al %: $1.500 × 1,5 = $2.250 → $2.300.
        enviar(put("/api/productos/editar/REV-0001"), "{\"modoPrecio\": \"MARGEN\", \"porcentajeGanancia\": 60}")
                .andExpect(jsonPath("$.modoPrecio").value("MARGEN"))
                .andExpect(jsonPath("$.precioUnitario").value(2400.0));
    }

    @Test
    void componentesDeReceta_incluyenLasPreparacionesBase() throws Exception {
        tortaConGanache();

        mockMvc.perform(get("/api/recetas/componentes"))
                .andExpect(jsonPath("$[?(@.codigo == 'ELA-GAN')].tipo").value("ELABORADO"))
                .andExpect(jsonPath("$[?(@.codigo == 'ELA-GAN')].familia").value("PESO"))
                .andExpect(jsonPath("$[?(@.codigo == 'ELA-GAN')].costoUnidadBase").value(11.75))
                .andExpect(jsonPath("$[?(@.codigo == 'MP-CH')].tipo").value("MATERIA_PRIMA"))
                // La torta se vende: no es componente.
                .andExpect(jsonPath("$[?(@.codigo == 'ELA-TOR')]").isEmpty());
    }

    @Test
    void preparacionBase_sinRindeEnPesoOVolumen_seRechaza() throws Exception {
        EspProducto harina = datos.crearMateriaPrima("MP-HA", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 1, 0);
        datos.crearElaborado("ELA-MAS", "Masa base", BigDecimal.ZERO, 0, false);

        receta("ELA-MAS", "12", null, fila(harina, "500", "GRAMO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Indique cuánto rinde Masa base en peso o volumen "
                        + "(gramo, kilo, mililitro o litro): es una preparación base."));
    }

    @Test
    void cicloAlGuardar_seRechaza() throws Exception {
        chocolate = datos.crearMateriaPrima("MP-CH", "Chocolate", new BigDecimal("18000"), UnidadMedida.KILO, 5, 0);
        EspProducto a = datos.crearElaborado("ELA-A", "Base A", BigDecimal.ZERO, 0, false);
        EspProducto b = datos.crearElaborado("ELA-B", "Base B", BigDecimal.ZERO, 0, false);
        String recetaA = receta("ELA-A", "1", "KILO", fila(chocolate, "100", "GRAMO"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        receta("ELA-B", "1", "KILO", fila(a, "200", "GRAMO")).andExpect(status().isCreated());

        // A pasa a usar B, que ya usa A: A → B → A.
        long idA = json.readTree(recetaA).get("id").asLong();
        enviar(put("/api/recetas/" + idA), "{\"nombre\": \"Receta A\", \"rinde\": 1, \"rindeUnidadMedida\": \"KILO\", "
                + "\"detalles\": [" + fila(chocolate, "100", "GRAMO") + "," + fila(b, "100", "GRAMO") + "]}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("No se puede usar Base B en la receta de Base A: Base B ya usa "
                        + "Base A (directa o indirectamente) y se formaría un ciclo."));
        // Tampoco puede usarse a sí misma.
        enviar(put("/api/recetas/" + idA), "{\"nombre\": \"Receta A\", \"rinde\": 1, \"rindeUnidadMedida\": \"KILO\", "
                + "\"detalles\": [" + fila(a, "100", "GRAMO") + "]}")
                .andExpect(status().isBadRequest());
    }

    /**
     * Un ciclo que ya está en los datos (cargado sin pasar por la validación)
     * corta la propagación con un error claro y no cambia nada. Sin la
     * transacción del test: cada pedido confirma o deshace la suya.
     */
    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    void cicloEnLosDatos_cortaLaPropagacion_yNoCambiaNada() throws Exception {
        TransactionTemplate tx = new TransactionTemplate(transactionManager);
        try {
            tx.executeWithoutResult(s -> {
                chocolate = datos.crearMateriaPrima("CIC-CH", "Chocolate ciclo", new BigDecimal("18000"),
                        UnidadMedida.KILO, 5, 0);
                EspProducto a = baseConFamilia("CIC-A", "Ciclo A");
                EspProducto b = baseConFamilia("CIC-B", "Ciclo B");
                Receta ra = new Receta(a, "Ciclo A", null, BigDecimal.ZERO);
                ra.addDetalle(new RecetaDetalle(ra, chocolate, new BigDecimal("100"), UnidadMedida.GRAMO));
                ra.addDetalle(new RecetaDetalle(ra, b, new BigDecimal("100"), UnidadMedida.GRAMO));
                recetaRepository.save(ra);
                Receta rb = new Receta(b, "Ciclo B", null, BigDecimal.ZERO);
                rb.addDetalle(new RecetaDetalle(rb, a, new BigDecimal("100"), UnidadMedida.GRAMO));
                recetaRepository.save(rb);
            });

            cambiarPrecioDelChocolate("30000")
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.error").value("Hay un ciclo entre recetas: Ciclo A → Ciclo B → Ciclo A. "
                            + "No se cambió nada: corrija una de esas recetas."));

            EspProducto sinCambios = productoRepository.findByCodigo("CIC-CH").orElseThrow();
            assertThat(sinCambios.getPresentacionPrecio()).isEqualByComparingTo("18000");
            assertThat(sinCambios.getCostoUnidadBase()).isEqualByComparingTo("18");
            assertThat(historialRepository.count()).isZero();
        } finally {
            jdbcTemplate.update("DELETE FROM recetas_detalles WHERE receta_id IN (SELECT r.id FROM recetas r "
                    + "JOIN esp_productos p ON p.id = r.esp_producto_id WHERE p.codigo LIKE 'CIC-%')");
            jdbcTemplate.update("DELETE FROM recetas WHERE esp_producto_id IN (SELECT id FROM esp_productos WHERE codigo LIKE 'CIC-%')");
            jdbcTemplate.update("DELETE FROM historial_precios");
            jdbcTemplate.update("DELETE FROM articulos_stock WHERE esp_producto_id IN (SELECT id FROM esp_productos WHERE codigo LIKE 'CIC-%')");
            jdbcTemplate.update("DELETE FROM esp_productos WHERE codigo LIKE 'CIC-%'");
        }
    }

    private EspProducto baseConFamilia(String codigo, String nombre) {
        EspProducto base = datos.crearElaborado(codigo, nombre, BigDecimal.ZERO, 0, false);
        base.setFamilia(UnidadMedida.GRAMO.getFamilia());
        base.setUnidadMedida(UnidadMedida.GRAMO);
        return productoRepository.save(base);
    }

    @Test
    void preciosCongelados_ventasPasadas_yCarrito() throws Exception {
        enviar(post("/api/productos/crear"), "{\"tipo\": \"REVENTA\", \"nombre\": \"Gaseosa\", \"precioCosto\": 1000, "
                + "\"porcentajeGanancia\": 50, \"stockActual\": 10}")
                .andExpect(jsonPath("$.precioUnitario").value(1500.0));
        String venta = "{\"lineas\": [{\"codigoProducto\": \"REV-0001\", \"cantidad\": 1%s}]}";
        enviar(post("/api/ventas"), venta.formatted("")).andExpect(status().isCreated());

        // Sube el costo: el precio pasa a $3.000.
        enviar(put("/api/productos/editar/REV-0001"), "{\"precioCosto\": 2000}")
                .andExpect(jsonPath("$.precioUnitario").value(3000.0));

        // La venta pasada conserva su precio.
        assertThat(jdbcTemplate.queryForObject("SELECT l.precio_unitario FROM lineas_venta l JOIN esp_productos p "
                + "ON p.id = l.codigo_producto WHERE p.codigo = 'REV-0001'", BigDecimal.class))
                .isEqualByComparingTo("1500");

        // Un carrito armado antes del cambio cobra el precio congelado ($1.500)...
        enviar(post("/api/ventas"), venta.formatted(", \"precioUnitario\": 1500"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.total").value(1500.0));
        // ...pero no cualquier precio.
        enviar(post("/api/ventas"), venta.formatted(", \"precioUnitario\": 1200"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "El precio de Gaseosa es $3000.00, no $1200. Quítelo del carrito y vuelva a agregarlo."));
        // Sin precio del carrito, se cobra el actual.
        enviar(post("/api/ventas"), venta.formatted("")).andExpect(jsonPath("$.total").value(3000.0));
    }

    @Test
    void historial_filtraPorFecha() throws Exception {
        tortaConGanache();
        cambiarPrecioDelChocolate("24000");

        String hoy = java.time.LocalDate.now().toString();
        String ayer = java.time.LocalDate.now().minusDays(1).toString();
        // Altas de las dos recetas (ganache y torta) + el cambio del chocolate (3 artículos).
        mockMvc.perform(get("/api/precios/historial").param("desde", hoy).param("hasta", hoy))
                .andExpect(jsonPath("$.length()").value(5));
        mockMvc.perform(get("/api/precios/historial").param("desde", ayer).param("hasta", ayer))
                .andExpect(jsonPath("$.length()").value(0));
        JsonNode filas = json.readTree(mockMvc.perform(get("/api/precios/historial").param("codigo", "MP-CH"))
                .andReturn().getResponse().getContentAsString());
        assertThat(filas.get(0).get("costoAnterior").decimalValue()).isEqualByComparingTo("18");
        assertThat(filas.get(0).get("costoNuevo").decimalValue()).isEqualByComparingTo("24");
    }
}
