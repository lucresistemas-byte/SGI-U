package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.services.DashboardService;
import com.sgiu_group.sgiu.services.MovimientoService;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * F-7: los rangos son [desde 00:00, hasta + 1 día 00:00). Lo que pasa justo a
 * la medianoche siguiente es del día siguiente, en las sumas igual que en el
 * listado (antes BETWEEN lo contaba en los dos días).
 */
class RangoFechasIntegrationTest extends AbstractIntegrationTest {

    private static final LocalDate DIA = LocalDate.of(2026, 3, 10);

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private MovimientoService movimientoService;
    @Autowired
    private DashboardService dashboardService;

    @BeforeEach
    void datos() {
        limpiarBaseDatos();
        EspProducto torta = datos.crearProducto("RANGO-1", "Torta", new BigDecimal("1000.00"), 10, 0);
        // Último instante del día y medianoche exacta del día siguiente.
        datos.crearVenta(torta, 1, "Efectivo", DIA.atTime(23, 59, 59));
        datos.crearVenta(torta, 2, "Efectivo", DIA.plusDays(1).atStartOfDay());
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal("500.00"), "Efectivo",
                "ALQUILER", DIA.plusDays(1).atStartOfDay());
    }

    @Test
    void balanceDelDiaNoIncluyeLaMedianocheSiguiente() {
        BalanceResponseDTO dia = movimientoService.calcularBalance(DIA, DIA);
        assertThat(dia.totalIngresos()).isEqualByComparingTo("1000.00");
        assertThat(dia.totalEgresos()).isEqualByComparingTo("0");
        assertThat(dia.movimientos()).hasSize(1);

        BalanceResponseDTO siguiente = movimientoService.calcularBalance(DIA.plusDays(1), DIA.plusDays(1));
        assertThat(siguiente.totalIngresos()).isEqualByComparingTo("2000.00");
        assertThat(siguiente.totalEgresos()).isEqualByComparingTo("500.00");
        assertThat(siguiente.movimientos()).hasSize(2);
    }

    @Test
    void dashboardDelDiaNoIncluyeLaMedianocheSiguiente() {
        DashboardResponseDTO dia = dashboardService.obtenerDashboard(DIA, DIA, null, null, null);
        assertThat(dia.getKpis().getCantidadVentas()).isEqualTo(1L);
        assertThat(dia.getKpis().getIngresosPeriodo()).isEqualByComparingTo("1000.00");
        assertThat(dia.getKpis().getEgresosPeriodo()).isEqualByComparingTo("0");
        assertThat(dia.getKpis().getTicketPromedio()).isEqualByComparingTo("1000.00");
        assertThat(dia.getGraficos().getVentasPorMetodoPago()).singleElement()
                .satisfies(m -> assertThat(m.getMontoTotal()).isEqualByComparingTo("1000.00"));
        assertThat(dia.getGraficos().getCategoriaMasVendida()).isNull();
        assertThat(dia.getKpis().getProductoMasVendido().getCantidadVendida()).isEqualTo(1L);
    }
}
