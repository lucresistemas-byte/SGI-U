package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WithMockUser
class BalanceControllerIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    @Test
    void obtenerBalance_conMovimientos_devuelveTotalesYMargen() throws Exception {
        datos.crearMovimiento(TipoMovimiento.INGRESO, new BigDecimal("1000.00"), "EFECTIVO",
                "Ventas", LocalDateTime.of(2026, 9, 15, 10, 0));
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal("400.00"), "TRANSFERENCIA",
                "Compras", LocalDateTime.of(2026, 9, 16, 11, 0));

        mockMvc.perform(get("/api/balance")
                        .param("fechaInicio", "2026-09-01")
                        .param("fechaFin", "2026-09-30"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalIngresos").value(1000.00))
                .andExpect(jsonPath("$.totalEgresos").value(400.00))
                .andExpect(jsonPath("$.margenNeto").value(600.00))
                .andExpect(jsonPath("$.movimientos").isArray());
    }

    @Test
    void obtenerBalance_sinMovimientos_devuelveCeros() throws Exception {
        mockMvc.perform(get("/api/balance")
                        .param("fechaInicio", "2026-09-01")
                        .param("fechaFin", "2026-09-30"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalIngresos").value(0))
                .andExpect(jsonPath("$.totalEgresos").value(0))
                .andExpect(jsonPath("$.margenNeto").value(0));
    }

    @Test
    void obtenerBalance_inicioPosteriorAlFin_devuelve400() throws Exception {
        mockMvc.perform(get("/api/balance")
                        .param("fechaInicio", "2026-09-30")
                        .param("fechaFin", "2026-09-01"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "La fecha de inicio no puede ser posterior a la fecha de fin."));
    }

    @Test
    void obtenerBalance_formatoDeFechaInvalido_devuelve400() throws Exception {
        mockMvc.perform(get("/api/balance")
                        .param("fechaInicio", "01-09-2026")
                        .param("fechaFin", "2026-09-30"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value(
                        "Formato de fecha inválido. Use el formato ISO: yyyy-MM-dd."));
    }
}