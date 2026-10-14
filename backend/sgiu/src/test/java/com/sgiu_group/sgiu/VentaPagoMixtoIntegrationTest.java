package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.ResultActions;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Parte 3 (D.4.1/D.4.2): una venta se paga con varias líneas (método + monto). */
@WithMockUser
class VentaPagoMixtoIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;
    @Autowired
    private VentaRepository ventaRepository;
    @Autowired
    private PagoVentaRepository pagoRepository;
    @Autowired
    private MovFinancieroRepository movRepository;
    @Autowired
    private MetodoPagoRepository metodoPagoRepository;

    private Long efectivo;
    private Long tarjeta;

    /** Torta a $500 (costo $300), 10 en stock: dos tortas = $1000. */
    @BeforeEach
    void datos() {
        EspProducto torta = datos.crearProducto("MIX-1", "Torta", new BigDecimal("500.00"), 10, 0);
        torta.setPrecioCosto(new BigDecimal("300.00"));
        productoRepository.save(torta);
        efectivo = datos.metodo("Efectivo").getId();
        tarjeta = datos.metodo("Tarjeta").getId();
    }

    private ResultActions vender(String pagos) throws Exception {
        return mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON)
                .content("{\"lineas\": [{\"codigoProducto\": \"MIX-1\", \"cantidad\": 2}], \"pagos\": [" + pagos + "]}"));
    }

    private static String pago(Long metodo, String monto) {
        return "{\"metodoPagoId\": " + metodo + ", \"monto\": " + monto + "}";
    }

    private Map<String, BigDecimal> pagosRegistrados() {
        return pagoRepository.findAll().stream().collect(Collectors.toMap(
                p -> p.getMetodoPago().getNombre(), PagoVenta::getMonto));
    }

    private Map<String, BigDecimal> movimientosRegistrados() {
        return movRepository.findAll().stream().collect(Collectors.toMap(
                m -> m.getMetodoPago().getNombre(), MovFinanciero::getMonto));
    }

    @Test
    void efectivoMasTarjeta_unPagoYUnMovimientoPorLinea() throws Exception {
        vender(pago(efectivo, "400") + "," + pago(tarjeta, "600"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.total").value(1000.0))
                .andExpect(jsonPath("$.vuelto").value(0))
                .andExpect(jsonPath("$.pagos.length()").value(2));

        assertThat(pagosRegistrados()).containsOnlyKeys("Efectivo", "Tarjeta");
        assertThat(pagosRegistrados().get("Efectivo")).isEqualByComparingTo("400");
        assertThat(pagosRegistrados().get("Tarjeta")).isEqualByComparingTo("600");
        assertThat(movimientosRegistrados().get("Efectivo")).isEqualByComparingTo("400");
        assertThat(movimientosRegistrados().get("Tarjeta")).isEqualByComparingTo("600");
    }

    @Test
    void efectivoConVuelto_registraSoloLoDeLaVenta() throws Exception {
        vender(pago(efectivo, "1500"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.vuelto").value(500.0))
                .andExpect(jsonPath("$.pagos[0].monto").value(1000.0));

        assertThat(pagosRegistrados().get("Efectivo")).isEqualByComparingTo("1000");
        assertThat(movimientosRegistrados().get("Efectivo")).isEqualByComparingTo("1000");
    }

    @Test
    void mixtoConVuelto_elVueltoSaleDelEfectivo() throws Exception {
        vender(pago(tarjeta, "600") + "," + pago(efectivo, "1000"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.vuelto").value(600.0));

        assertThat(pagosRegistrados().get("Tarjeta")).isEqualByComparingTo("600");
        assertThat(pagosRegistrados().get("Efectivo")).isEqualByComparingTo("400");
    }

    @Test
    void pagosInsuficientes_seRechazanYNoQuedaNada() throws Exception {
        vender(pago(efectivo, "300") + "," + pago(tarjeta, "200"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Los pagos ($500.00) no cubren el total de la venta ($1000.00). Falta $500.00."));

        assertThat(ventaRepository.count()).isZero();
        assertThat(pagoRepository.count()).isZero();
        assertThat(movRepository.count()).isZero();
        assertThat(stockRepository.findByEspProducto_Codigo("MIX-1").orElseThrow().getCantidad()).isEqualByComparingTo("10");
    }

    @Test
    void unMetodoQueNoEsEfectivo_noPuedePasarseDelTotal() throws Exception {
        vender(pago(tarjeta, "1200"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Los pagos que no son en efectivo ($1200.00) superan el total "
                        + "de la venta ($1000.00). Solo el efectivo puede tener vuelto."));
        assertThat(ventaRepository.count()).isZero();
    }

    @Test
    void metodoInactivoORepetido_seRechazan() throws Exception {
        vender(pago(tarjeta, "500") + "," + pago(tarjeta, "500"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El método Tarjeta está dos veces; sume los montos en una sola línea."));

        MetodoPago t = metodoPagoRepository.findById(tarjeta).orElseThrow();
        t.setActivo(false);
        metodoPagoRepository.save(t);
        vender(pago(tarjeta, "1000"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El método de pago Tarjeta está desactivado."));
    }

    @Test
    void dashboardYBalance_desglosanPorMetodoSinDuplicarElCosto() throws Exception {
        vender(pago(efectivo, "400") + "," + pago(tarjeta, "600")).andExpect(status().isCreated());
        String hoy = LocalDate.now().toString();

        mockMvc.perform(get("/api/dashboard").param("fechaDesde", hoy).param("fechaHasta", hoy))
                .andExpect(jsonPath("$.kpis.ingresosPeriodo").value(1000.0))
                .andExpect(jsonPath("$.kpis.cantidadVentas").value(1))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[0].metodoPago").value("Efectivo"))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[0].montoTotal").value(400.0))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[1].metodoPago").value("Tarjeta"))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[1].montoTotal").value(600.0));
        mockMvc.perform(get("/api/dashboard").param("fechaDesde", hoy).param("fechaHasta", hoy)
                        .param("metodoPagoId", tarjeta.toString()))
                .andExpect(jsonPath("$.kpis.ingresosPeriodo").value(600.0))
                .andExpect(jsonPath("$.kpis.cantidadVentas").value(1));

        // Costo de la venta: 2 x $300 = $600, repartido 40/60 (no $1200).
        mockMvc.perform(get("/api/balance").param("fechaInicio", hoy).param("fechaFin", hoy))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalIngresos").value(1000.0))
                .andExpect(jsonPath("$.costoTotal").value(600.0))
                .andExpect(jsonPath("$.gananciaReal").value(400.0));
    }

    @Test
    void sinPagos_seCobraTodoConElMetodoIndicado() throws Exception {
        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"metodoPago\": " + tarjeta + ", \"lineas\": [{\"codigoProducto\": \"MIX-1\", \"cantidad\": 2}]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.pagos[0].metodoPago").value("Tarjeta"))
                .andExpect(jsonPath("$.pagos[0].monto").value(1000.0));
    }
}
