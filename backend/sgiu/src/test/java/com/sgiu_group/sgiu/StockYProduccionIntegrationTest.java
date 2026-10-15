package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MovimientoStock;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.TipoMovimientoStock;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MovimientoStockRepository;
import com.sgiu_group.sgiu.repositories.ProduccionRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Etapa 5: producción por tanda e historial de stock. Chocolate (1 kg),
 * crema (1 l) y harina (2 kg); ganache (preparación base: 400 g + 400 ml,
 * rinde 800 g); torta (rinde 1: 300 g de ganache + 100 g de chocolate + 200 g
 * de harina) y porción (rinde 8: 400 g de harina).
 */
@WithMockUser(username = "sandra")
class StockYProduccionIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;
    @Autowired
    private MovimientoStockRepository movimientoRepository;
    @Autowired
    private ProduccionRepository produccionRepository;
    @Autowired
    private ObjectMapper json;

    private EspProducto chocolate;
    private EspProducto crema;
    private EspProducto harina;

    private ResultActions enviar(MockHttpServletRequestBuilder req, String body) throws Exception {
        return mockMvc.perform(req.contentType(MediaType.APPLICATION_JSON).content(body));
    }

    private static String fila(EspProducto a, String cantidad, String unidad) {
        return "{\"articuloId\": " + a.getId() + ", \"cantidad\": " + cantidad + ", \"unidadMedida\": \"" + unidad + "\"}";
    }

    private void receta(String codigo, String rinde, String rindeUnidadMedida, String... filas) throws Exception {
        enviar(post("/api/recetas"), "{\"espProductoCodigo\": \"" + codigo + "\", \"nombre\": \"Receta " + codigo
                + "\", \"rinde\": " + rinde + (rindeUnidadMedida != null ? ", \"rindeUnidadMedida\": \"" + rindeUnidadMedida + "\"" : "")
                + ", \"detalles\": [" + String.join(",", filas) + "]}").andExpect(status().isCreated());
    }

    private ResultActions producir(String codigo, int cantidad, boolean confirmar) throws Exception {
        return enviar(post("/api/productos/" + codigo + "/produccion"),
                "{\"cantidad\": " + cantidad + ", \"confirmarFaltantes\": " + confirmar + "}");
    }

    private BigDecimal stock(EspProducto a) {
        return stockRepository.findByEspProducto(a).orElseThrow().getCantidad();
    }

    private List<MovimientoStock> movimientos(String codigo) {
        return movimientoRepository.findByArticulo_CodigoOrderByIdAsc(codigo);
    }

    /** Ingredientes, ganache, torta y porción con sus recetas; [harinaKilos] de stock de harina. */
    private void tortaYPorcion(int harinaGramos) throws Exception {
        chocolate = datos.crearMateriaPrima("STK-CH", "Chocolate", new BigDecimal("18000"), UnidadMedida.KILO, 1, 0);
        crema = datos.crearMateriaPrima("STK-CR", "Crema", new BigDecimal("5500"), UnidadMedida.LITRO, 1, 0);
        harina = datos.crearMateriaPrima("STK-HA", "Harina", new BigDecimal("1200"), UnidadMedida.KILO, 0, 0);
        stockRepository.findByEspProducto(harina).orElseThrow().setCantidad(BigDecimal.valueOf(harinaGramos));
        EspProducto ganache = datos.crearElaborado("STK-GAN", "Ganache", BigDecimal.ZERO, 0, false);
        receta("STK-GAN", "800", "GRAMO", fila(chocolate, "400", "GRAMO"), fila(crema, "400", "MILILITRO"));
        datos.crearElaborado("STK-TOR", "Torta", BigDecimal.ZERO, 0, true);
        receta("STK-TOR", "1", null, fila(ganache, "300", "GRAMO"), fila(chocolate, "100", "GRAMO"),
                fila(harina, "200", "GRAMO"));
        datos.crearElaborado("STK-POR", "Porción", BigDecimal.ZERO, 0, true);
        receta("STK-POR", "8", null, fila(harina, "400", "GRAMO"));
    }

    @Test
    void producir_descuentaSegunRindeYBajaPorLaPreparacionBase() throws Exception {
        tortaYPorcion(2000);
        EspProducto torta = productoRepository.findByCodigo("STK-TOR").orElseThrow();

        // 2 tortas: 600 g de ganache = 0,75 recetas → 300 g de chocolate y 300 ml de crema;
        // más 200 g de chocolate y 400 g de harina directos.
        producir("STK-TOR", 2, false)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.cantidad").value(2.0))
                .andExpect(jsonPath("$.conFaltantes").value(false))
                .andExpect(jsonPath("$.stockActual").value(2))
                .andExpect(jsonPath("$.costoUnitario").value(torta.getPrecioCosto().doubleValue()))
                .andExpect(jsonPath("$.consumos.length()").value(3));

        assertThat(stock(chocolate)).isEqualByComparingTo("500");
        assertThat(stock(crema)).isEqualByComparingTo("700");
        assertThat(stock(harina)).isEqualByComparingTo("1600");
        assertThat(stock(torta)).isEqualByComparingTo("2");
        // La ganache no tiene stock: no se mueve.
        assertThat(movimientos("STK-GAN")).isEmpty();

        // Porción (rinde 8): 4 porciones = media receta = 200 g de harina.
        producir("STK-POR", 4, false).andExpect(status().isCreated());
        assertThat(stock(harina)).isEqualByComparingTo("1400");

        // Movimientos: entrada de la torta y consumos con la producción de referencia.
        assertThat(movimientos("STK-TOR")).extracting(MovimientoStock::getTipo, m -> m.getCantidad().intValue())
                .containsExactly(tuple(TipoMovimientoStock.PRODUCCION, 2));
        assertThat(movimientos("STK-CH")).extracting(MovimientoStock::getTipo)
                .containsExactly(TipoMovimientoStock.CONSUMO_PRODUCCION);
        MovimientoStock consumo = movimientos("STK-CH").get(0);
        assertThat(consumo.getCantidad()).isEqualByComparingTo("-500");
        assertThat(consumo.getStockResultante()).isEqualByComparingTo("500");
        assertThat(consumo.getProduccion()).isNotNull();
        assertThat(consumo.getUsuario()).isEqualTo("sandra");
        assertThat(produccionRepository.count()).isEqualTo(2);
    }

    @Test
    void puedoProducirHasta_segunElStockDeLosComponentes() throws Exception {
        tortaYPorcion(2000);

        // Por torta: 250 g de chocolate (1 kg → 4), 150 ml de crema (→ 6), 200 g de harina (→ 10).
        mockMvc.perform(get("/api/productos"))
                .andExpect(jsonPath("$[?(@.codigo == 'STK-TOR')].puedeProducir").value(4))
                .andExpect(jsonPath("$[?(@.codigo == 'STK-POR')].puedeProducir").value(40))
                .andExpect(jsonPath("$[?(@.codigo == 'STK-GAN')].puedeProducir")
                        .value(org.hamcrest.Matchers.contains(org.hamcrest.Matchers.nullValue())));
    }

    @Test
    void conFaltantes_avisaSinAplicar_yConfirmadoQuedaNegativo() throws Exception {
        tortaYPorcion(300);

        producir("STK-TOR", 2, false)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.codigo").value("FALTAN_COMPONENTES"))
                .andExpect(jsonPath("$.faltantes.length()").value(1))
                .andExpect(jsonPath("$.faltantes[0].codigo").value("STK-HA"))
                .andExpect(jsonPath("$.faltantes[0].mensaje").value(
                        "Faltan 100 g de Harina: hay 300 g, se necesitan 400 g."));
        // No se aplicó nada.
        assertThat(produccionRepository.count()).isZero();
        assertThat(movimientos("STK-TOR")).isEmpty();
        assertThat(stock(harina)).isEqualByComparingTo("300");
        assertThat(stock(chocolate)).isEqualByComparingTo("1000");

        producir("STK-TOR", 2, true)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.conFaltantes").value(true))
                .andExpect(jsonPath("$.consumos[?(@.codigo == 'STK-HA')].negativo").value(true))
                .andExpect(jsonPath("$.consumos[?(@.codigo == 'STK-HA')].stockResultanteTexto").value("−100 g"));
        assertThat(stock(harina)).isEqualByComparingTo("-100");
        assertThat(produccionRepository.findAll().get(0).getFaltantes())
                .isEqualTo("Faltan 100 g de Harina: hay 300 g, se necesitan 400 g.");

        // Materia Prima lo muestra negativo; una compra que no alcanza a cubrirlo se acepta.
        mockMvc.perform(get("/api/materias-primas"))
                .andExpect(jsonPath("$[?(@.codigo == 'STK-HA')].stockActual").value(-100.0));
        enviar(post("/api/materias-primas/" + harina.getId() + "/ajuste-stock"),
                "{\"cantidad\": 50, \"unidad\": \"GRAMO\", \"motivo\": \"Compra chica\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stockActual").value(-50.0));
    }

    @Test
    void preparacionBaseYReventa_noSeProducen() throws Exception {
        tortaYPorcion(2000);
        datos.crearProducto("STK-REV", "Gaseosa", new BigDecimal("1500"), 5, 0);

        producir("STK-GAN", 1, false)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Ganache es una preparación base: no tiene stock. Sus "
                        + "ingredientes se descuentan al producir lo que la usa."));
        producir("STK-REV", 1, false).andExpect(status().isBadRequest());
        // Sumar stock de un elaborado "a mano" pide producir.
        enviar(put("/api/productos/stock/STK-TOR"), "{\"cantidad\": 2, \"motivo\": \"Horneé\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Para sumar stock de Torta use Producir: descuenta sus "
                        + "ingredientes o insumos."));
    }

    @Test
    void paquete_alProducirDescuentaSuArmado() throws Exception {
        EspProducto caja = datos.crearArticuloDeMateriaPrima(TipoArticulo.INSUMO, "STK-CJ", "Caja", new BigDecimal("900"),
                UnidadMedida.UNIDAD, 10, 0);
        EspProducto cinta = datos.crearArticuloDeMateriaPrima(TipoArticulo.INSUMO, "STK-CI", "Cinta", new BigDecimal("300"),
                UnidadMedida.METRO, 10, 0);
        enviar(post("/api/paquetes"), "{\"nombre\": \"Paquete\", \"montoFijo\": 1000, \"armado\": ["
                + fila(caja, "1", "UNIDAD") + "," + fila(cinta, "50", "CENTIMETRO") + "]}")
                .andExpect(status().isCreated());

        producir("PAQ-0001", 3, false).andExpect(status().isCreated()).andExpect(jsonPath("$.stockActual").value(3));

        assertThat(stock(caja)).isEqualByComparingTo("7");
        assertThat(stock(cinta)).isEqualByComparingTo("850");
        assertThat(movimientos("STK-CI")).extracting(MovimientoStock::getTipo, m -> m.getCantidad().intValue())
                .containsExactly(tuple(TipoMovimientoStock.CONSUMO_PRODUCCION, -150));
    }

    @Test
    void todoCambioDeStockDejaUnMovimiento_conMotivoYTipo() throws Exception {
        // Alta con stock inicial (Productos y Materia Prima).
        enviar(post("/api/productos/crear"), "{\"tipo\": \"REVENTA\", \"nombre\": \"Gaseosa\", \"precioCosto\": 1000, "
                + "\"porcentajeGanancia\": 50, \"stockActual\": 10}").andExpect(status().isCreated());
        enviar(post("/api/materias-primas"), "{\"tipo\": \"MATERIA_PRIMA\", \"nombre\": \"Azúcar\", \"unidadMedida\": \"KILO\", "
                + "\"presentacionCantidad\": 1, \"presentacionUnidad\": \"KILO\", \"presentacionPrecio\": 1300, "
                + "\"stockActual\": 2, \"stockUnidad\": \"KILO\"}").andExpect(status().isCreated());
        EspProducto azucar = productoRepository.findByCodigo("MP-0001").orElseThrow();

        // Ajustes de Productos: compra, merma.
        enviar(put("/api/productos/stock/REV-0001"), "{\"cantidad\": 5, \"motivo\": \"Llegó el pedido\"}")
                .andExpect(jsonPath("$.stockActual").value(15));
        enviar(put("/api/productos/stock/REV-0001"), "{\"cantidad\": -1, \"motivo\": \"Se rompió\", \"tipo\": \"MERMA\"}")
                .andExpect(jsonPath("$.stockActual").value(14));
        enviar(put("/api/productos/stock/REV-0001"), "{\"cantidad\": 1, \"motivo\": \"x\", \"tipo\": \"MERMA\"}")
                .andExpect(status().isBadRequest());
        enviar(put("/api/productos/stock/REV-0001"), "{\"cantidad\": 1, \"motivo\": \"\"}")
                .andExpect(status().isBadRequest());

        // Ajustes de Materia Prima: compra por presentación y merma.
        enviar(post("/api/materias-primas/" + azucar.getId() + "/ajuste-stock"),
                "{\"cantidad\": 1, \"unidad\": \"PRESENTACION\", \"motivo\": \"Compra\", \"tipo\": \"COMPRA\"}")
                .andExpect(jsonPath("$.stockActual").value(3000.0));
        enviar(post("/api/materias-primas/" + azucar.getId() + "/ajuste-stock"),
                "{\"cantidad\": -200, \"unidad\": \"GRAMO\", \"motivo\": \"Se humedeció\", \"tipo\": \"MERMA\"}")
                .andExpect(jsonPath("$.stockActual").value(2800.0));

        assertThat(movimientos("REV-0001"))
                .extracting(MovimientoStock::getTipo, m -> m.getCantidad().intValue(), m -> m.getStockResultante().intValue(),
                        MovimientoStock::getMotivo)
                .containsExactly(
                        tuple(TipoMovimientoStock.AJUSTE, 10, 10, "Stock inicial"),
                        tuple(TipoMovimientoStock.COMPRA, 5, 15, "Llegó el pedido"),
                        tuple(TipoMovimientoStock.MERMA, -1, 14, "Se rompió"));
        assertThat(movimientos("MP-0001"))
                .extracting(MovimientoStock::getTipo, m -> m.getCantidad().intValue())
                .containsExactly(tuple(TipoMovimientoStock.AJUSTE, 2000), tuple(TipoMovimientoStock.COMPRA, 1000),
                        tuple(TipoMovimientoStock.MERMA, -200));

        // "Ver historial": más recientes primero, filtrable por tipo y por fecha.
        String hoy = java.time.LocalDate.now().toString();
        mockMvc.perform(get("/api/stock/movimientos/MP-0001"))
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].tipo").value("MERMA"))
                .andExpect(jsonPath("$[0].cantidadTexto").value("−200 g"))
                .andExpect(jsonPath("$[0].stockResultanteTexto").value("2,8 kg"))
                .andExpect(jsonPath("$[0].usuario").value("sandra"));
        mockMvc.perform(get("/api/stock/movimientos/MP-0001").param("tipo", "COMPRA"))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].cantidadTexto").value("+1 kg"));
        mockMvc.perform(get("/api/stock/movimientos/MP-0001").param("desde", "2020-01-01").param("hasta", "2020-01-31"))
                .andExpect(jsonPath("$.length()").value(0));
        mockMvc.perform(get("/api/stock/movimientos/MP-0001").param("desde", hoy).param("hasta", hoy))
                .andExpect(jsonPath("$.length()").value(3));
    }

    @Test
    void cadaLineaDeVentaDejaUnMovimientoVenta() throws Exception {
        datos.crearProducto("STK-V1", "Alfajor", new BigDecimal("500"), 10, 0);
        datos.crearReventaMateriaPrima("STK-V2", "Caja de chocolate", 1200, new BigDecimal("27000"), "Caja", 100,
                new BigDecimal("60"), 1000);

        String respuesta = enviar(post("/api/ventas"), "{\"lineas\": [{\"codigoProducto\": \"STK-V1\", \"cantidad\": 3}, "
                + "{\"codigoProducto\": \"STK-V2\", \"cantidad\": 2}]}")
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        long ventaId = json.readTree(respuesta).get("id").asLong();

        MovimientoStock alfajor = movimientos("STK-V1").get(0);
        assertThat(alfajor.getTipo()).isEqualTo(TipoMovimientoStock.VENTA);
        assertThat(alfajor.getCantidad()).isEqualByComparingTo("-3");
        assertThat(alfajor.getStockResultante()).isEqualByComparingTo("7");
        assertThat(alfajor.getVenta().getId()).isEqualTo(ventaId);
        // 2 cajas de 100 g.
        assertThat(movimientos("STK-V2").get(0).getCantidad()).isEqualByComparingTo("-200");
    }
}
