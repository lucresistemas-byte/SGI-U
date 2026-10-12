package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MateriaPrima;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
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
    @Autowired
    private MateriaPrimaRepository materiaPrimaRepository;
    @Autowired
    private RecetaRepository recetaRepository;

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
                .andExpect(jsonPath("$.error").value("Producto no encontrado: NO-EXISTE"));

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
                .andExpect(jsonPath("$.error").value(
                        "Stock insuficiente para Poco Stock (código VTA-2): disponible 2, solicitado 5."));

        assertThat(stockRepository.findByEspProducto_Codigo(idCodigo).orElseThrow().getCantidad())
                .isEqualTo(2);
        assertThat(ventaRepository.count()).isZero();
        assertThat(movFinancieroRepository.count()).isZero();
    }

    @Test
    void crearVenta_jsonMalFormado_devuelve400() throws Exception {
        mockMvc.perform(post("/api/ventas")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{lineas rotas"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Error en el formato de los datos o valor inválido."));
    }

    // --- Venta por tanda: solo se descuenta el producto final ---

    /** Producto elaborado con receta: 0,2 kg de harina por unidad. */
    private MateriaPrima elaboradoConReceta(EspProducto producto, int stockHarina) {
        MateriaPrima harina = materiaPrimaRepository.save(new MateriaPrima(
                "VTA-HAR", "Harina", new BigDecimal("1200.00"), UnidadMedida.KILO, stockHarina, 0));
        Receta receta = new Receta(producto, "Torta", null, BigDecimal.ZERO);
        receta.addDetalle(new RecetaDetalle(receta, harina, new BigDecimal("0.200"), UnidadMedida.KILO));
        recetaRepository.save(receta);
        return harina;
    }

    @Test
    void crearVenta_productoConReceta_descuentaSoloElProductoFinalYNoLosInsumos() throws Exception {
        EspProducto torta = datos.crearProducto("VTA-TORTA", "Torta", new BigDecimal("7600.00"), 5, 0);
        MateriaPrima harina = elaboradoConReceta(torta, 3);

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON).content(venta(torta, 1)))
                .andExpect(status().isCreated());

        assertThat(stockRepository.findByEspProducto_Codigo("VTA-TORTA").orElseThrow().getCantidad())
                .isEqualTo(4);
        // Antes: 3 -> 2 (descontaba la receta y además redondeaba 0,2 kg a 1 kg).
        assertThat(materiaPrimaRepository.findById(harina.getId()).orElseThrow().getStockActual())
                .isEqualTo(3);
    }

    @Test
    void crearVenta_productoConRecetaSinInsumosSuficientes_igualSeVendeSiHayProductoFinal() throws Exception {
        EspProducto torta = datos.crearProducto("VTA-TORTA", "Torta", new BigDecimal("7600.00"), 2, 0);
        elaboradoConReceta(torta, 0);

        // Antes: 500 "Error interno del servidor" (InsumoInsuficienteException).
        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON).content(venta(torta, 1)))
                .andExpect(status().isCreated());

        assertThat(stockRepository.findByEspProducto_Codigo("VTA-TORTA").orElseThrow().getCantidad())
                .isEqualTo(1);
    }

    @Test
    void crearVenta_productoConRecetaSinStockFinal_devuelve400JsonConElProducto() throws Exception {
        EspProducto torta = datos.crearProducto("VTA-TORTA", "Torta", new BigDecimal("7600.00"), 0, 0);
        elaboradoConReceta(torta, 10);

        mockMvc.perform(post("/api/ventas").contentType(MediaType.APPLICATION_JSON).content(venta(torta, 1)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Stock insuficiente para Torta (código VTA-TORTA): disponible 0, solicitado 1."));
        assertThat(ventaRepository.count()).isZero();
    }
}
