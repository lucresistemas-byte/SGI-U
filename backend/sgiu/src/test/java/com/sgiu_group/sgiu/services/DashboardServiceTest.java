package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.FechasInvalidasException;
import com.sgiu_group.sgiu.exceptions.FiltroInvalidoException;
import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.LineaVentaRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DashboardServiceTest {

    @Mock
    private VentaRepository ventaRepository;
    @Mock
    private LineaVentaRepository lineaVentaRepository;
    @Mock
    private MovFinancieroRepository movFinancieroRepository;
    @Mock
    private ArticuloStockRepository articuloStockRepository;
    @Mock
    private PagoVentaRepository pagoVentaRepository;
    @Mock
    private MetodoPagoRepository metodoPagoRepository;

    @InjectMocks
    private DashboardService dashboardService;

    private static List<Object[]> fila(Object[]... filas) {
        return java.util.Arrays.asList(filas);
    }

    private final LocalDate desde = LocalDate.of(2026, 9, 1);
    private final LocalDate hasta = LocalDate.of(2026, 9, 30);

    @Test
    void obtenerDashboard_fechaDesdePosteriorAlHasta_lanzaFechasInvalidas() {
        assertThatThrownBy(() -> dashboardService.obtenerDashboard(hasta, desde, null, null, null))
                .isInstanceOf(FechasInvalidasException.class)
                .hasMessage("La fecha desde no puede ser mayor que la fecha hasta");
    }

    @Test
    void obtenerDashboard_metodoPagoInvalido_lanzaFiltroInvalido() {
        assertThatThrownBy(() -> dashboardService.obtenerDashboard(desde, hasta, 99L, null, null))
                .isInstanceOf(FiltroInvalidoException.class)
                .hasMessage("El método de pago especificado no existe.");
    }

    @Test
    void obtenerDashboard_conDatos_calculaKpisYGraficos() {
        LocalDate hoy = LocalDate.of(2026, 9, 15);
        Date fechaSql = Date.valueOf(hoy);

        when(movFinancieroRepository.sumByTipoYMetodoEnRango(any(), any(), eq(TipoMovimiento.INGRESO), any()))
                .thenReturn(new BigDecimal("1000.00"));
        when(movFinancieroRepository.sumByTipoYMetodoEnRango(any(), any(), eq(TipoMovimiento.EGRESO), any()))
                .thenReturn(new BigDecimal("400.00"));
        when(ventaRepository.countVentasEnRango(any(), any())).thenReturn(3L);
        when(ventaRepository.sumTotalVentasEnRango(any(), any())).thenReturn(new BigDecimal("600.00"));
        when(lineaVentaRepository.findTopProductosVendidos(any(), any()))
                .thenReturn(fila(new Object[]{1L, "Producto A", 4L, new BigDecimal("250.00")}));
        when(lineaVentaRepository.findTopProductosPorGanancia(any(), any(), any()))
                .thenReturn(fila(new Object[]{1L, "Producto A", 4L, new BigDecimal("250.00"), new BigDecimal("100.00")}));
        when(movFinancieroRepository.findIngresosEgresosPorDia(any(), any(), any()))
                .thenReturn(fila(new Object[]{fechaSql, new BigDecimal("1000.00"), new BigDecimal("400.00")}));
        when(pagoVentaRepository.findVentasAgrupadasPorMetodoPago(any(), any()))
                .thenReturn(fila(new Object[]{"Efectivo", 3L, new BigDecimal("600.00")}));
        when(articuloStockRepository.findStockCritico(any()))
                .thenReturn(List.of(stock("Producto A", 3, 5), stock("Producto C", 1, 2)));
        when(movFinancieroRepository.findSaldoNetoAcumuladoPorDia(any(), any(), any()))
                .thenReturn(fila(new Object[]{fechaSql, new BigDecimal("600.00")}));

        DashboardResponseDTO response = dashboardService.obtenerDashboard(desde, hasta, null, null, null);

        assertThat(response.getFiltrosAplicados().getFechaDesde()).isEqualTo(desde);
        assertThat(response.getKpis().getIngresosPeriodo()).isEqualByComparingTo("1000.00");
        assertThat(response.getKpis().getEgresosPeriodo()).isEqualByComparingTo("400.00");
        assertThat(response.getKpis().getSaldoNeto()).isEqualByComparingTo("600.00");
        assertThat(response.getKpis().getMargenNetoPorcentaje()).isEqualByComparingTo("60.0000");
        assertThat(response.getKpis().getCantidadVentas()).isEqualTo(3L);
        assertThat(response.getKpis().getTicketPromedio()).isEqualByComparingTo("200.00");
        assertThat(response.getKpis().getCantidadProductosStockBajo()).isEqualTo(2L);
        assertThat(response.getKpis().getProductoMasVendido().getNombre()).isEqualTo("Producto A");

        assertThat(response.getGraficos().getIngresosVsEgresosPorDia()).hasSize(1);
        assertThat(response.getGraficos().getVentasPorMetodoPago()).hasSize(1);
        assertThat(response.getGraficos().getVentasPorMetodoPago().get(0).getMetodoPago()).isEqualTo("Efectivo");
        assertThat(response.getGraficos().getTopProductosPorGanancia()).singleElement()
                .satisfies(p -> assertThat(p.ganancia()).isEqualByComparingTo("150.00"));
        assertThat(response.getGraficos().getEvolucionSaldoNeto()).hasSize(1);
        assertThat(response.getGraficos().getProductosConMenorStock()).hasSize(2);
        assertThat(response.getGraficos().getProductosConMenorStock().get(0).getEstado()).isEqualTo("BAJO");

        assertThat(response.getMetadata().isHayDatos()).isTrue();
        assertThat(response.getMetadata().getMensaje()).isEqualTo("Dashboard generado correctamente");
    }

    @Test
    void obtenerDashboard_sinDatos_devuelveMetricasEnCero() {
        when(lineaVentaRepository.findTopProductosVendidos(any(), any())).thenReturn(List.of());
        when(movFinancieroRepository.findIngresosEgresosPorDia(any(), any(), any())).thenReturn(List.of());
        when(pagoVentaRepository.findVentasAgrupadasPorMetodoPago(any(), any())).thenReturn(List.of());
        when(articuloStockRepository.findStockCritico(any())).thenReturn(List.of());
        when(movFinancieroRepository.findSaldoNetoAcumuladoPorDia(any(), any(), any())).thenReturn(List.of());

        DashboardResponseDTO response = dashboardService.obtenerDashboard(desde, hasta, null, null, null);

        assertThat(response.getKpis().getIngresosPeriodo()).isEqualByComparingTo("0");
        assertThat(response.getKpis().getEgresosPeriodo()).isEqualByComparingTo("0");
        assertThat(response.getKpis().getCantidadVentas()).isEqualTo(0L);
        assertThat(response.getKpis().getTicketPromedio()).isEqualByComparingTo("0");
        assertThat(response.getKpis().getProductoMasVendido()).isNull();
        assertThat(response.getGraficos().getTopProductosPorGanancia()).isEmpty();
        assertThat(response.getMetadata().isHayDatos()).isFalse();
        assertThat(response.getMetadata().getMensaje()).isEqualTo("No hay datos para el período seleccionado");
    }

    @Test
    void obtenerDashboard_productoEnStockCero_seMarcaComoAgotado() {
        when(lineaVentaRepository.findTopProductosVendidos(any(), any())).thenReturn(List.of());
        when(movFinancieroRepository.findIngresosEgresosPorDia(any(), any(), any())).thenReturn(List.of());
        when(pagoVentaRepository.findVentasAgrupadasPorMetodoPago(any(), any())).thenReturn(List.of());
        when(movFinancieroRepository.findSaldoNetoAcumuladoPorDia(any(), any(), any())).thenReturn(List.of());
        when(articuloStockRepository.findStockCritico(any()))
                .thenReturn(List.of(stock("Producto B", 0, 5)));

        DashboardResponseDTO response = dashboardService.obtenerDashboard(desde, hasta, null, null, null);

        assertThat(response.getGraficos().getProductosConMenorStock().get(0).getEstado()).isEqualTo("AGOTADO");
    }

    @Test
    void obtenerDashboard_tipoTransaccionEgreso_ignoraIngresos() {
        when(lineaVentaRepository.findTopProductosVendidos(any(), any())).thenReturn(List.of());
        when(movFinancieroRepository.findIngresosEgresosPorDia(any(), any(), any())).thenReturn(List.of());
        when(pagoVentaRepository.findVentasAgrupadasPorMetodoPago(any(), any())).thenReturn(List.of());
        when(articuloStockRepository.findStockCritico(any())).thenReturn(List.of());
        when(movFinancieroRepository.findSaldoNetoAcumuladoPorDia(any(), any(), any())).thenReturn(List.of());
        when(movFinancieroRepository.sumByTipoYMetodoEnRango(any(), any(), eq(TipoMovimiento.EGRESO), any()))
                .thenReturn(new BigDecimal("400.00"));

        DashboardResponseDTO response = dashboardService.obtenerDashboard(desde, hasta, null, null, "EGRESO");

        assertThat(response.getKpis().getIngresosPeriodo()).isEqualByComparingTo("0");
        assertThat(response.getKpis().getEgresosPeriodo()).isEqualByComparingTo("400.00");
        assertThat(response.getKpis().getSaldoNeto()).isEqualByComparingTo("-400.00");
    }

    private static com.sgiu_group.sgiu.models.entities.ArticuloStock stock(String nombre, int cantidad, int minimo) {
        var producto = new com.sgiu_group.sgiu.models.entities.EspProducto("P-" + nombre, nombre, BigDecimal.ONE);
        var stock = new com.sgiu_group.sgiu.models.entities.ArticuloStock(producto, cantidad);
        stock.setStockMinimo(BigDecimal.valueOf(minimo));
        return stock;
    }
}
