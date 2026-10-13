package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WithMockUser
class MovimientoControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private TestDataFactory datos;
    @Autowired
    private MovFinancieroRepository repository;

    private String body(MovimientoRequestDTO dto) throws Exception {
        return objectMapper.writeValueAsString(dto);
    }

    @Test
    void crear_valido_devuelve201ConDatosPersistidos() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "INGRESO", new BigDecimal("150.00"), datos.metodo("TRANSFERENCIA").getId(), "VENTA", "Pago cliente", null);

        mockMvc.perform(post("/api/movimientos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.tipo").value("INGRESO"))
                .andExpect(jsonPath("$.monto").isNumber())
                .andExpect(jsonPath("$.metodoPago").value("Transferencia"))
                .andExpect(jsonPath("$.categoria").value("VENTA"))
                .andExpect(jsonPath("$.descripcion").value("Pago cliente"));

        assertThat(repository.count()).isEqualTo(1);
        assertThat(repository.findAll().getFirst().getTipo()).isEqualTo(TipoMovimiento.INGRESO);
    }

    @Test
    void crear_tipoInvalido_devuelve400() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "CRIPTO", new BigDecimal("10.00"), datos.metodo("EFECTIVO").getId(), "Otro", null, null);

        mockMvc.perform(post("/api/movimientos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El tipo de movimiento debe ser INGRESO o EGRESO."));

        assertThat(repository.count()).isZero();
    }

    @Test
    void crear_montoNegativo_devuelve400PorValidacion() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "INGRESO", new BigDecimal("-5.00"), datos.metodo("EFECTIVO").getId(), "Otro", null, null);

        mockMvc.perform(post("/api/movimientos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El monto debe ser mayor a cero."));
    }

    @Test
    void crear_montoNull_devuelve400PorValidacion() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "INGRESO", null, datos.metodo("EFECTIVO").getId(), "Otro", null, null);

        mockMvc.perform(post("/api/movimientos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El monto es obligatorio."));
    }

    @Test
    void listar_devuelveMovimientosOrdenadosPorFechaDescendente() throws Exception {
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal("30.00"), "EFECTIVO",
                "ANTERIOR", LocalDateTime.of(2026, 9, 19, 10, 0));
        datos.crearMovimiento(TipoMovimiento.INGRESO, new BigDecimal("100.00"), "TARJETA",
                "POSTERIOR", LocalDateTime.of(2026, 9, 21, 10, 0));

        mockMvc.perform(get("/api/movimientos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].categoria").value("POSTERIOR"))
                .andExpect(jsonPath("$[1].categoria").value("ANTERIOR"));
    }

    @Test
    void listar_ventaConCosto_devuelveCostoYGananciaDeLaVenta() throws Exception {
        EspProducto producto = datos.crearProducto(
                "MOV-COSTO", "Producto con costo", new BigDecimal("100.00"), 10, 0);
        producto.setPrecioCosto(new BigDecimal("40.00"));
        datos.crearVenta(producto, 2, "EFECTIVO", LocalDateTime.of(2026, 9, 21, 10, 0));

        mockMvc.perform(get("/api/movimientos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].monto").value(200.00))
                .andExpect(jsonPath("$[0].costo").value(80.00))
                .andExpect(jsonPath("$[0].ganancia").value(120.00));
    }

    // --- Categoría según el tipo ---
    // INGRESO: VENTA, OTRO_INGRESO. EGRESO: COMPRA, SERVICIOS, ALQUILER, SUELDOS, OTRO.

    @Test
    void crear_egresoConCategoriaDeIngreso_devuelve400ConMensajeClaro() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "EGRESO", new BigDecimal("10.00"), datos.metodo("EFECTIVO").getId(), "VENTA", null, null);

        mockMvc.perform(post("/api/movimientos").contentType(MediaType.APPLICATION_JSON).content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "La categoría VENTA no corresponde a un EGRESO. Categorías válidas: "
                                + "COMPRA, SERVICIOS, ALQUILER, SUELDOS, OTRO."));
        assertThat(repository.count()).isZero();
    }

    @Test
    void crear_ingresoConCategoriaDeEgreso_devuelve400() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "INGRESO", new BigDecimal("10.00"), datos.metodo("EFECTIVO").getId(), "COMPRA", null, null);

        mockMvc.perform(post("/api/movimientos").contentType(MediaType.APPLICATION_JSON).content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "La categoría COMPRA no corresponde a un INGRESO. Categorías válidas: "
                                + "VENTA, OTRO_INGRESO."));
    }

    @Test
    void crear_categoriaInexistente_devuelve400() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "EGRESO", new BigDecimal("10.00"), datos.metodo("EFECTIVO").getId(), "Retiro", null, null);

        mockMvc.perform(post("/api/movimientos").contentType(MediaType.APPLICATION_JSON).content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "La categoría RETIRO no corresponde a un EGRESO. Categorías válidas: "
                                + "COMPRA, SERVICIOS, ALQUILER, SUELDOS, OTRO."));
    }

    @Test
    void crear_sinCategoria_devuelve400() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "EGRESO", new BigDecimal("10.00"), datos.metodo("EFECTIVO").getId(), "  ", null, null);

        mockMvc.perform(post("/api/movimientos").contentType(MediaType.APPLICATION_JSON).content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("La categoría es obligatoria."));
    }

    @Test
    void crear_categoriaEnMinusculas_seGuardaComoCodigo() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "EGRESO", new BigDecimal("10.00"), datos.metodo("EFECTIVO").getId(), " sueldos ", null, null);

        mockMvc.perform(post("/api/movimientos").contentType(MediaType.APPLICATION_JSON).content(body(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.categoria").value("SUELDOS"));
    }
}
