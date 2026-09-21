package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
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

@WithMockUser
class VentaControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private ArticuloStockRepository stockRepository;
    @Autowired
    private VentaRepository ventaRepository;
    @Autowired
    private PagoVentaRepository pagoRepository;
    @Autowired
    private MovFinancieroRepository movFinancieroRepository;

    private String venta(EspProducto producto, int cantidad) {
        return "{\"metodoPago\": null, \"lineas\": [{\"codigoProducto\": \""
                + producto.getCodigo() + "\", \"cantidad\": " + cantidad + "}]}";
    }

    @Test
    void crearVenta_valida_descuentaStockYRegistraPagoYMovimiento() throws Exception {
        EspProducto producto = datos.crearProducto("VTA-1", "Producto V", new BigDecimal("100.00"), 10, 2);
        String idCodigo = producto.getCodigo();

        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venta(producto, 3)))
                .andExpect(status().isCreated());

        // Stock: 10 - 3 = 7
        assertThat(stockRepository.findByEspProducto_Codigo(idCodigo).orElseThrow().getCantidad())
                .isEqualTo(7);

        // Una venta con total = 100 * 3 = 300
        assertThat(ventaRepository.count()).isEqualTo(1);
        assertThat(ventaRepository.findAll().get(0).getTotal()).isEqualByComparingTo("300.00");

        // Un pago por 300 con método por defecto EFECTIVO
        assertThat(pagoRepository.findAll()).hasSize(1);
        assertThat(pagoRepository.findAll().get(0).getMetodo()).isEqualTo("EFECTIVO");

        // Un movimiento financiero de INGRESO
        assertThat(movFinancieroRepository.findAll()).hasSize(1);
        MovFinanciero mov = movFinancieroRepository.findAll().getFirst();
        assertThat(mov.getTipo()).isEqualTo(TipoMovimiento.INGRESO);
        assertThat(mov.getMonto()).isEqualByComparingTo("300.00");
        assertThat(mov.getMetodoPago()).isEqualTo("EFECTIVO");
        assertThat(mov.getCategoria()).isEqualTo("VENTA");
    }

    @Test
    void crearVenta_productoInexistente_devuelve404() throws Exception {
        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"lineas\": [{\"codigoProducto\": \"NO-EXISTE\", \"cantidad\": 1}]}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$").value("Producto no encontrado: NO-EXISTE"));

        assertThat(ventaRepository.count()).isZero();
        assertThat(movFinancieroRepository.count()).isZero();
    }

    @Test
    void crearVenta_stockInsuficiente_devuelve400YNoDescuenta() throws Exception {
        EspProducto producto = datos.crearProducto("VTA-2", "Poco Stock", new BigDecimal("50.00"), 2, 1);
        String idCodigo = producto.getCodigo();

        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venta(producto, 5)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$").value("Stock insuficiente para: " + idCodigo));

        assertThat(stockRepository.findByEspProducto_Codigo(idCodigo).orElseThrow().getCantidad())
                .isEqualTo(2);
        assertThat(ventaRepository.count()).isZero();
        assertThat(movFinancieroRepository.count()).isZero();
    }

    @Test
    void crearVenta_jsonMalFormado_seManejaComoError500() throws Exception {
        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{lineas rotas"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value(true));
    }
}