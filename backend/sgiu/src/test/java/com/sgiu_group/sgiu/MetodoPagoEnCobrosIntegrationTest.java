package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Parte 2: ventas, movimientos y pedidos guardan el método por clave foránea
 * a metodos_pago; uno desactivado no se acepta en cobros nuevos, pero los
 * registros viejos lo siguen mostrando.
 */
@WithMockUser
class MetodoPagoEnCobrosIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private MetodoPagoRepository metodoPagoRepository;
    @Autowired
    private PagoVentaRepository pagoRepository;
    @Autowired
    private MovFinancieroRepository movRepository;

    private void desactivar(MetodoPago m) {
        m.setActivo(false);
        metodoPagoRepository.save(m);
    }

    @Test
    void venta_guardaElMetodoYNoElNumero() throws Exception {
        EspProducto p = datos.crearProducto("MPC-1", "Alfajor", new BigDecimal("500.00"), 10, 0);
        Long mercadoPago = datos.metodo("Mercado Pago").getId();

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"metodoPago\": " + mercadoPago + ", \"lineas\": [{\"codigoProducto\": \"MPC-1\", \"cantidad\": 2}]}"))
                .andExpect(status().isCreated());

        // Antes quedaba "2" como texto (M-3/E-22).
        assertThat(pagoRepository.findAll()).singleElement()
                .satisfies(pago -> assertThat(pago.getMetodoPago().getNombre()).isEqualTo("Mercado Pago"));
        assertThat(movRepository.findAll()).singleElement()
                .satisfies(mov -> assertThat(mov.getMetodoPago().getNombre()).isEqualTo("Mercado Pago"));
    }

    @Test
    void metodoDesactivado_noSeAceptaEnVentasMovimientosNiPedidos() throws Exception {
        datos.crearProducto("MPC-2", "Alfajor", new BigDecimal("500.00"), 10, 0);
        MetodoPago tarjeta = datos.metodo("Tarjeta");
        desactivar(tarjeta);
        String mensaje = "El método de pago Tarjeta está desactivado.";

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"metodoPago\": " + tarjeta.getId() + ", \"lineas\": [{\"codigoProducto\": \"MPC-2\", \"cantidad\": 1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
        mockMvc.perform(post("/api/movimientos").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tipo\": \"EGRESO\", \"monto\": 100, \"metodoPagoId\": " + tarjeta.getId()
                                + ", \"categoria\": \"COMPRA\", \"descripcion\": \"Harina\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
        mockMvc.perform(post("/api/pedidos").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clienteNombre\": \"Ana\", \"clienteTelefono\": \"1155550000\", "
                                + "\"descripcion\": \"Torta\", \"montoTotal\": 1000, \"senia\": 300, "
                                + "\"metodoPagoSeniaId\": " + tarjeta.getId() + "}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(mensaje));
    }

    @Test
    void pedido_seniaYAbonoGuardanSuMetodo() throws Exception {
        Long transferencia = datos.metodo("Transferencia").getId();
        String creado = mockMvc.perform(post("/api/pedidos").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"clienteNombre\": \"Ana\", \"clienteTelefono\": \"1155550000\", "
                                + "\"descripcion\": \"Torta\", \"montoTotal\": 1000, \"senia\": 300, "
                                + "\"metodoPagoSeniaId\": " + transferencia + "}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.abonos[0].metodoPago").value("Transferencia"))
                .andExpect(jsonPath("$.abonos[0].metodoPagoId").value(transferencia))
                .andReturn().getResponse().getContentAsString();
        long id = Long.parseLong(creado.replaceAll(".*?\"id\":(\\d+).*", "$1"));

        // Sin método: Efectivo.
        mockMvc.perform(post("/api/pedidos/" + id + "/abonar").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"monto\": 200}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.abonos[1].metodoPago").value("Efectivo"));
    }

    @Test
    void historial_conservaElMetodoAunqueSeDesactive() throws Exception {
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal("80.00"), "TARJETA", "COMPRA", LocalDateTime.now());
        desactivar(datos.metodo("Tarjeta"));

        mockMvc.perform(get("/api/movimientos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].metodoPago").value("Tarjeta"));
    }

    @Test
    void dashboard_filtraLosMontosPorMetodo() throws Exception {
        EspProducto p = datos.crearProducto("MPC-3", "Alfajor", new BigDecimal("100.00"), 10, 0);
        datos.crearVenta(p, 2, "EFECTIVO", LocalDateTime.now());
        datos.crearVenta(p, 1, "TRANSFERENCIA", LocalDateTime.now());
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal("30.00"), "EFECTIVO", "COMPRA", LocalDateTime.now());

        String hoy = LocalDate.now().toString();
        mockMvc.perform(get("/api/dashboard").param("fechaDesde", hoy).param("fechaHasta", hoy)
                        .param("metodoPagoId", datos.metodo("Transferencia").getId().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kpis.ingresosPeriodo").value(100.0))
                .andExpect(jsonPath("$.kpis.egresosPeriodo").value(0))
                .andExpect(jsonPath("$.kpis.cantidadVentas").value(1));
        mockMvc.perform(get("/api/dashboard").param("fechaDesde", hoy).param("fechaHasta", hoy))
                .andExpect(jsonPath("$.kpis.ingresosPeriodo").value(300.0))
                .andExpect(jsonPath("$.kpis.egresosPeriodo").value(30.0))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[0].metodoPago").value("Efectivo"))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[0].montoTotal").value(200.0))
                .andExpect(jsonPath("$.graficos.ventasPorMetodoPago[1].metodoPago").value("Transferencia"));
    }
}
