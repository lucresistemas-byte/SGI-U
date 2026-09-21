package com.sgiu_group.sgiu;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
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
                "INGRESO", new BigDecimal("150.00"), "TRANSFERENCIA", "Ventas", "Pago cliente", null);

        mockMvc.perform(post("/api/movimientos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.tipo").value("INGRESO"))
                .andExpect(jsonPath("$.monto").isNumber())
                .andExpect(jsonPath("$.metodoPago").value("TRANSFERENCIA"))
                .andExpect(jsonPath("$.categoria").value("Ventas"))
                .andExpect(jsonPath("$.descripcion").value("Pago cliente"));

        assertThat(repository.count()).isEqualTo(1);
        assertThat(repository.findAll().getFirst().getTipo()).isEqualTo(TipoMovimiento.INGRESO);
    }

    @Test
    void crear_tipoInvalido_devuelve400() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "CRIPTO", new BigDecimal("10.00"), "EFECTIVO", "Otro", null, null);

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
                "INGRESO", new BigDecimal("-5.00"), "EFECTIVO", "Otro", null, null);

        mockMvc.perform(post("/api/movimientos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(dto)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("El monto debe ser mayor a cero."));
    }

    @Test
    void crear_montoNull_devuelve400PorValidacion() throws Exception {
        MovimientoRequestDTO dto = new MovimientoRequestDTO(
                "INGRESO", null, "EFECTIVO", "Otro", null, null);

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
}