package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.ResultActions;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Etapa 3: catálogo único. Materias primas, insumos y reventa + materia prima
 * son filas de esp_productos con su stock en articulos_stock (unidad base).
 * Ejemplo: caja de chocolate de 100 g, comprada en bulto de 12 cajas a
 * $27.000 ($2.250 la caja), vendida con 60 % de ganancia ($3.600).
 */
@WithMockUser
class CatalogoUnicoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;
    @Autowired
    private RecetaRepository recetaRepository;

    /** 3.650 g en stock: 36 cajas enteras y 50 g sueltos. */
    private EspProducto cajaDeChocolate() {
        return datos.crearReventaMateriaPrima("RMP-T1", "Caja de chocolate 100 g", 1200,
                new BigDecimal("27000"), "Caja", 100, new BigDecimal("60"), 3650);
    }

    private ResultActions vender(String codigo, int cantidad) throws Exception {
        return mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON)
                .content("{\"lineas\": [{\"codigoProducto\": \"" + codigo + "\", \"cantidad\": " + cantidad + "}]}"));
    }

    private ResultActions ajustar(EspProducto articulo, String cantidad, String unidad) throws Exception {
        return mockMvc.perform(post("/api/materias-primas/" + articulo.getId() + "/ajuste-stock")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cantidad\": " + cantidad + ", \"unidad\": \"" + unidad + "\", \"motivo\": \"Compra\"}"));
    }

    private BigDecimal stockEnBase(EspProducto articulo) {
        return stockRepository.findByEspProducto(articulo).orElseThrow().getCantidad();
    }

    private static String chocolate(String extra) {
        return "{\"tipo\": \"REVENTA_MATERIA_PRIMA\", \"nombre\": \"Caja de chocolate 100 g\", "
                + "\"unidadMedida\": \"GRAMO\", \"presentacionDescripcion\": \"Bulto de 12 cajas\", "
                + "\"presentacionCantidad\": 1.2, \"presentacionUnidad\": \"KILO\", \"presentacionPrecio\": 27000"
                + extra + "}";
    }

    @Test
    void laTablaMateriasPrimasYaNoExiste_yLaMateriaPrimaEsUnArticuloDelCatalogo() throws Exception {
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE UPPER(TABLE_NAME) = 'MATERIAS_PRIMAS'",
                Integer.class)).isZero();

        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tipo\": \"MATERIA_PRIMA\", \"nombre\": \"Harina\", \"unidadMedida\": \"KILO\", "
                                + "\"presentacionCantidad\": 25, \"presentacionUnidad\": \"KILO\", "
                                + "\"presentacionPrecio\": 30000, \"stockActual\": 2, \"stockUnidad\": \"KILO\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("MP-0001"));

        EspProducto harina = productoRepository.findByCodigo("MP-0001").orElseThrow();
        assertThat(harina.getTipo()).isEqualTo(TipoArticulo.MATERIA_PRIMA);
        assertThat(harina.getCostoUnidadBase()).isEqualByComparingTo("1.2");
        assertThat(stockEnBase(harina)).isEqualByComparingTo("2000");
    }

    @Test
    void productosListaLoQueSeVende_yMateriaPrimaLoQueVaEnRecetas() throws Exception {
        cajaDeChocolate();
        datos.crearMateriaPrima("MP-T1", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 1, 0);
        datos.crearProducto("REV-T1", "Gaseosa", new BigDecimal("1500"), 5, 0);

        mockMvc.perform(get("/api/productos"))
                .andExpect(jsonPath("$[*].codigo", hasItem("RMP-T1")))
                .andExpect(jsonPath("$[*].codigo", hasItem("REV-T1")))
                .andExpect(jsonPath("$[*].codigo", not(hasItem("MP-T1"))));
        mockMvc.perform(get("/api/materias-primas"))
                .andExpect(jsonPath("$[*].codigo", hasItem("RMP-T1")))
                .andExpect(jsonPath("$[*].codigo", hasItem("MP-T1")))
                .andExpect(jsonPath("$[*].codigo", not(hasItem("REV-T1"))));
    }

    @Test
    void pos_ofreceSoloCajasEnteras_conPrecioYStockEnUnidadesDeVenta() throws Exception {
        cajaDeChocolate();

        mockMvc.perform(get("/api/productos").param("vendible", "true"))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].stockActual").value(36))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].unidadVenta").value("Caja"))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].precioCosto").value(2250.0))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].precioUnitario").value(3600.0));
    }

    @Test
    void venderUnaCaja_descuenta100Gramos_yLoSueltoNoSeVende() throws Exception {
        EspProducto caja = cajaDeChocolate();

        vender("RMP-T1", 1).andExpect(status().isCreated()).andExpect(jsonPath("$.total").value(3600.0));
        assertThat(stockEnBase(caja)).isEqualByComparingTo("3550");

        // Quedan 35 cajas y 50 g sueltos: la caja 36 no se puede vender.
        vender("RMP-T1", 36)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Stock insuficiente para Caja de chocolate 100 g "
                        + "(código RMP-T1): disponible 35, solicitado 36."));
        vender("RMP-T1", 35).andExpect(status().isCreated());
        assertThat(stockEnBase(caja)).isEqualByComparingTo("50");
        vender("RMP-T1", 1).andExpect(status().isBadRequest());
    }

    @Test
    void materiaPrima_muestraLasCajasYLoSuelto() throws Exception {
        cajaDeChocolate();

        mockMvc.perform(get("/api/materias-primas"))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].stockActual").value(3650.0))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].stockUnidadesVenta").value(36))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].stockSuelto").value(50.0))
                .andExpect(jsonPath("$[?(@.codigo == 'RMP-T1')].ventaUnidadContenido").value(100.0));
    }

    @Test
    void cargaDeStock_porBulto_porCaja_oEnGramos() throws Exception {
        EspProducto caja = cajaDeChocolate();

        // Llegó 1 bulto = 12 cajas = 1.200 g.
        ajustar(caja, "1", "PRESENTACION").andExpect(status().isOk())
                .andExpect(jsonPath("$.stockActual").value(4850.0))
                .andExpect(jsonPath("$.stockUnidadesVenta").value(48));
        ajustar(caja, "2", "UNIDAD_VENTA").andExpect(jsonPath("$.stockActual").value(5050.0));
        ajustar(caja, "-0.05", "KILO").andExpect(jsonPath("$.stockActual").value(5000.0))
                .andExpect(jsonPath("$.stockSuelto").value(0.0));
        ajustar(caja, "1", "LITRO").andExpect(status().isBadRequest());

        // Unidad de venta solo en la reventa + materia prima.
        EspProducto harina = datos.crearMateriaPrima("MP-T2", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 0, 0);
        ajustar(harina, "1", "UNIDAD_VENTA").andExpect(status().isBadRequest());
    }

    @Test
    void alta_compradaPorBulto_calculaElCostoDeLaCajaYElPrecio() throws Exception {
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(chocolate(", \"ventaUnidadNombre\": \"Caja\", \"ventaUnidadCantidad\": 100, "
                                + "\"ventaUnidadUnidad\": \"GRAMO\", \"porcentajeGanancia\": 60, "
                                + "\"stockActual\": 2, \"stockUnidad\": \"PRESENTACION\"")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("RMP-0001"))
                .andExpect(jsonPath("$.costoUnidadBase").value(22.5))
                .andExpect(jsonPath("$.costoUnidadVenta").value(2250.0))
                .andExpect(jsonPath("$.precioVenta").value(3600.0))
                .andExpect(jsonPath("$.precioManual").value(false))
                .andExpect(jsonPath("$.stockActual").value(2400.0))
                .andExpect(jsonPath("$.stockUnidadesVenta").value(24));
    }

    @Test
    void alta_sinUnidadDeVenta_seVendeLaPresentacionDeCompra() throws Exception {
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON)
                        .content(chocolate(", \"porcentajeGanancia\": 50")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.ventaUnidadNombre").value("Bulto de 12 cajas"))
                .andExpect(jsonPath("$.ventaUnidadContenido").value(1200.0))
                .andExpect(jsonPath("$.precioVenta").value(40500.0));
    }

    @Test
    void costoDeReceta_conGramosDeLaCaja() throws Exception {
        EspProducto caja = cajaDeChocolate();
        datos.crearElaborado("ELA-T1", "Brownie", BigDecimal.ONE, 0, true);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"ELA-T1\", \"nombre\": \"Brownie\", \"rinde\": 12, "
                                + "\"detalles\": [{\"articuloId\": " + caja.getId()
                                + ", \"cantidad\": 150, \"unidadMedida\": \"GRAMO\"}]}"))
                .andExpect(status().isCreated())
                // 150 g × $22,50 = $3.375; 12 porciones → $281,25 cada una.
                .andExpect(jsonPath("$.detalles[0].articuloCodigo").value("RMP-T1"))
                .andExpect(jsonPath("$.detalles[0].articuloTipo").value("REVENTA_MATERIA_PRIMA"))
                .andExpect(jsonPath("$.detalles[0].subtotal").value(3375.0))
                .andExpect(jsonPath("$.costoTotal").value(3375.0))
                .andExpect(jsonPath("$.costoPorUnidad").value(281.25));
    }

    @Test
    void unaRecetaNoPuedeUsarUnProductoDeReventa() throws Exception {
        EspProducto gaseosa = datos.crearProducto("REV-T2", "Gaseosa", new BigDecimal("1500"), 5, 0);
        datos.crearElaborado("ELA-T2", "Torta", BigDecimal.ONE, 0, true);

        mockMvc.perform(post("/api/recetas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"espProductoCodigo\": \"ELA-T2\", \"nombre\": \"Torta\", \"rinde\": 1, "
                                + "\"detalles\": [{\"articuloId\": " + gaseosa.getId() + ", \"cantidad\": 1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Gaseosa es de reventa y no se puede usar en recetas. "
                        + "Use materias primas, insumos o reventa + materia prima."));
    }

    @Test
    void precioAMano_seConservaCuandoCambiaElCosto() throws Exception {
        String alta = chocolate(", \"ventaUnidadNombre\": \"Caja\", \"ventaUnidadCantidad\": 100, "
                + "\"ventaUnidadUnidad\": \"GRAMO\", \"porcentajeGanancia\": 60, \"precioVenta\": 4000");
        mockMvc.perform(post("/api/materias-primas").contentType(MediaType.APPLICATION_JSON).content(alta))
                .andExpect(jsonPath("$.precioVenta").value(4000.0))
                .andExpect(jsonPath("$.precioManual").value(true));
        Long id = productoRepository.findByCodigo("RMP-0001").orElseThrow().getId();

        // El bulto sube a $30.000: la caja cuesta $2.500 y el precio sigue en $4.000.
        mockMvc.perform(put("/api/materias-primas/" + id).contentType(MediaType.APPLICATION_JSON)
                        .content(alta.replace("27000", "30000")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.costoUnidadVenta").value(2500.0))
                .andExpect(jsonPath("$.precioVenta").value(4000.0))
                .andExpect(jsonPath("$.precioManual").value(true))
                .andExpect(jsonPath("$.porcentajeGanancia").value(60.0));

        // Sin precio a mano vuelve a seguir al costo: $2.500 × 1,6.
        mockMvc.perform(put("/api/materias-primas/" + id).contentType(MediaType.APPLICATION_JSON)
                        .content(alta.replace("27000", "30000").replace(", \"precioVenta\": 4000", "")))
                .andExpect(jsonPath("$.precioVenta").value(4000.0))
                .andExpect(jsonPath("$.precioManual").value(false));
        mockMvc.perform(put("/api/materias-primas/" + id).contentType(MediaType.APPLICATION_JSON)
                        .content(alta.replace("27000", "36000").replace(", \"precioVenta\": 4000", "")))
                .andExpect(jsonPath("$.costoUnidadVenta").value(3000.0))
                .andExpect(jsonPath("$.precioVenta").value(4800.0));
    }

    @Test
    void cascadaDePrecios_alCambiarElCostoDeLaCaja_seActualizanElla_yElElaboradoQueLaUsa() throws Exception {
        EspProducto caja = cajaDeChocolate();
        EspProducto brownie = datos.crearElaborado("ELA-T3", "Brownie", BigDecimal.ONE, 0, true);
        brownie.setPorcentajeGanancia(new BigDecimal("100"));
        Receta receta = new Receta(brownie, "Brownie", null, BigDecimal.ZERO);
        receta.setRinde(new BigDecimal("12"));
        receta.addDetalle(new RecetaDetalle(receta, caja, new BigDecimal("150"), UnidadMedida.GRAMO));
        recetaRepository.save(receta);

        // Bulto a $36.000 → $30 el gramo; la caja $3.000 → $4.800; brownie: 150 g × $30 / 12 = $375 → $750.
        mockMvc.perform(put("/api/materias-primas/" + caja.getId()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\": \"Caja de chocolate 100 g\", \"unidadMedida\": \"GRAMO\", "
                                + "\"presentacionCantidad\": 1200, \"presentacionUnidad\": \"GRAMO\", "
                                + "\"presentacionPrecio\": 36000, \"ventaUnidadNombre\": \"Caja\", "
                                + "\"ventaUnidadCantidad\": 100, \"ventaUnidadUnidad\": \"GRAMO\", "
                                + "\"porcentajeGanancia\": 60}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.precioVenta").value(4800.0));

        EspProducto actualizado = productoRepository.findByCodigo("ELA-T3").orElseThrow();
        assertThat(actualizado.getPrecioCosto()).isEqualByComparingTo("375.00");
        assertThat(actualizado.getPrecioUnitario()).isEqualByComparingTo("750.00");
    }

    @Test
    void productos_ajusteDeStockDeLaCaja_esEnCajas() throws Exception {
        EspProducto caja = cajaDeChocolate();

        mockMvc.perform(put("/api/productos/stock/RMP-T1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cantidad\": 2, \"motivo\": \"Compra\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stockActual").value(38));
        assertThat(stockEnBase(caja)).isEqualByComparingTo("3850");
    }
}
