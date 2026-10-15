package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.ResultadoPeriodoDTO;
import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.models.dtos.dashboard.ProductoMasVendidoDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.LineaVenta;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import com.sgiu_group.sgiu.services.DashboardService;
import com.sgiu_group.sgiu.services.MovimientoService;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Los datos de la demo (db/demo) con fechas fijas de octubre de 2026, para
 * verificar los números de docs/ANALISIS_FINANZAS.md: ventas 76.800, costo
 * 37.905, gastos 123.000 (45.000 de compras de mercadería).
 */
class FinanzasDemoIntegrationTest extends AbstractIntegrationTest {

    private static final LocalDate INICIO_MES = LocalDate.of(2026, 10, 1);
    private static final LocalDate HOY = LocalDate.of(2026, 10, 15);

    @Autowired
    private TestDataFactory datos;
    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private VentaRepository ventaRepository;
    @Autowired
    private PagoVentaRepository pagoRepository;
    @Autowired
    private MovFinancieroRepository movRepository;
    @Autowired
    private DashboardService dashboardService;
    @Autowired
    private MovimientoService movimientoService;

    private EspProducto tarta, torta, alfajor, coca, agua, bombones;

    @BeforeEach
    void demo() {
        limpiarBaseDatos();
        tarta = elaborado(producto("ELA-0001", "Tarta de coco", "10800", "4895"));
        torta = elaborado(producto("ELA-0002", "Torta de chocolate", "21200", "10095"));
        alfajor = elaborado(producto("ELA-0003", "Alfajor de maicena", "5300", "2120"));
        coca = producto("REV-0001", "Coca-Cola 500 ml", "1500", "900");
        agua = producto("REV-0002", "Agua mineral 500 ml", "900", "500");
        bombones = producto("REV-0003", "Caja de bombones 100 g", "6000", "3500");

        gasto("ALQUILER", "60000", "Transferencia", dia(9, 23, 45));
        gasto("COMPRA", "45000", "Transferencia", dia(10, 23, 45));
        vender(dia(11, 23, 45), Map.of("Efectivo", "13800"), tarta, 1, coca, 2);
        vender(dia(12, 23, 45), Map.of("Transferencia", "21200"), torta, 1);
        gasto("SERVICIOS", "18000", "Efectivo", dia(12, 23, 45));
        vender(dia(13, 23, 45), Map.of("Efectivo", "12200"), agua, 1, bombones, 1, alfajor, 1);
        vender(dia(14, 21, 45), Map.of("Transferencia", "6900"), bombones, 1, agua, 1);
        Map<String, String> mixto = new LinkedHashMap<>();
        mixto.put("Efectivo", "10000");
        mixto.put("Tarjeta", "12700");
        vender(dia(14, 22, 45), mixto, torta, 1, coca, 1);
    }

    @Test
    void topProductos_losCincoMasVendidosConSuGanancia() {
        DashboardResponseDTO mes = dashboardService.obtenerDashboard(INICIO_MES, HOY, null, null, null);

        // Por unidades; con igual cantidad, primero el que más vendió en pesos.
        assertThat(mes.getGraficos().getTopProductosMasVendidos())
                .extracting(ProductoMasVendidoDTO::getNombre)
                .containsExactly("Coca-Cola 500 ml", "Torta de chocolate", "Caja de bombones 100 g",
                        "Agua mineral 500 ml", "Tarta de coco");
        ProductoMasVendidoDTO coca = mes.getGraficos().getTopProductosMasVendidos().getFirst();
        assertThat(coca.getCantidadVendida()).isEqualTo(3L);
        assertThat(coca.getMontoTotal()).isEqualByComparingTo("4500");
        assertThat(coca.getGanancia()).isEqualByComparingTo("1800");
        ProductoMasVendidoDTO torta = mes.getGraficos().getTopProductosMasVendidos().get(1);
        assertThat(torta.getCosto()).isEqualByComparingTo("20190");
        assertThat(torta.getGanancia()).isEqualByComparingTo("22210");
    }

    @Test
    void filtroPorTipo_elaborados_ventasCostoGananciaYTopDelTipo_gastosDeTodoElNegocio() {
        DashboardResponseDTO mes = dashboardService.obtenerDashboard(
                INICIO_MES, HOY, null, null, null, TipoArticulo.ELABORADO);

        // Tarta (10.800), torta × 2 (42.400) y alfajor (5.300).
        assertThat(mes.getKpis().getIngresosPeriodo()).isEqualByComparingTo("58500");
        assertThat(mes.getKpis().getCantidadVentas()).isEqualTo(4L);
        assertThat(mes.getKpis().getTicketPromedio()).isEqualByComparingTo("14625");
        ResultadoPeriodoDTO r = mes.getKpis().getResultado();
        assertThat(r.ventas()).isEqualByComparingTo("58500");
        assertThat(r.costoVendido()).isEqualByComparingTo("27205");
        assertThat(r.gananciaBruta()).isEqualByComparingTo("31295");
        assertThat(r.margenBrutoPorcentaje()).isEqualByComparingTo("53.50");
        // Los gastos son de todo el negocio: no cambian con el tipo.
        assertThat(mes.getKpis().getEgresosPeriodo()).isEqualByComparingTo("123000");
        assertThat(mes.getKpis().getSaldoNeto()).isEqualByComparingTo("-46200");
        assertThat(r.gastos()).isEqualByComparingTo("78000");
        assertThat(r.gananciaNeta()).isEqualByComparingTo("-39105");
        assertThat(mes.getGraficos().getTopProductosMasVendidos())
                .extracting(ProductoMasVendidoDTO::getNombre)
                .containsExactly("Torta de chocolate", "Tarta de coco", "Alfajor de maicena");
        assertThat(mes.getFiltrosAplicados().getTipoProducto()).isEqualTo("ELABORADO");
    }

    @Test
    void filtroPorTipo_reventa() {
        DashboardResponseDTO mes = dashboardService.obtenerDashboard(
                INICIO_MES, HOY, null, null, null, TipoArticulo.REVENTA);

        ResultadoPeriodoDTO r = mes.getKpis().getResultado();
        assertThat(r.ventas()).isEqualByComparingTo("18300");
        assertThat(r.costoVendido()).isEqualByComparingTo("10700");
        assertThat(r.gananciaBruta()).isEqualByComparingTo("7600");
        assertThat(mes.getKpis().getCantidadVentas()).isEqualTo(4L);
        assertThat(mes.getKpis().getTicketPromedio()).isEqualByComparingTo("4575");
        assertThat(mes.getGraficos().getTopProductosMasVendidos())
                .extracting(ProductoMasVendidoDTO::getNombre)
                .containsExactly("Coca-Cola 500 ml", "Caja de bombones 100 g", "Agua mineral 500 ml");
    }

    @Test
    void filtroPorTipoSinVentas_enCero() {
        DashboardResponseDTO mes = dashboardService.obtenerDashboard(
                INICIO_MES, HOY, null, null, null, TipoArticulo.PAQUETE);

        assertThat(mes.getKpis().getIngresosPeriodo()).isEqualByComparingTo("0");
        assertThat(mes.getKpis().getCantidadVentas()).isZero();
        assertThat(mes.getKpis().getTicketPromedio()).isEqualByComparingTo("0");
        assertThat(mes.getKpis().getResultado().margenBrutoPorcentaje()).isNull();
        assertThat(mes.getGraficos().getTopProductosMasVendidos()).isEmpty();
        assertThat(mes.getKpis().getEgresosPeriodo()).isEqualByComparingTo("123000");
    }

    @Test
    void filtroPorTipoYMetodo_soloLaParteCobradaConEseMetodo() {
        Long efectivo = datos.metodo("Efectivo").getId();
        DashboardResponseDTO mes = dashboardService.obtenerDashboard(
                INICIO_MES, HOY, efectivo, null, null, TipoArticulo.ELABORADO);

        // Ventas 1 (tarta) y 3 (alfajor) enteras en efectivo; de la torta de
        // la venta 5, 10.000 de 22.700.
        assertThat(mes.getKpis().getCantidadVentas()).isEqualTo(3L);
        assertThat(mes.getKpis().getResultado().ventas()).isEqualByComparingTo("25439.21");
        assertThat(mes.getKpis().getResultado().costoVendido()).isEqualByComparingTo("11462.14");
    }

    @Test
    void filtroPorTipoQueNoSeVende_esUnError() {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> dashboardService.obtenerDashboard(
                        INICIO_MES, HOY, null, null, null, TipoArticulo.MATERIA_PRIMA))
                .isInstanceOf(com.sgiu_group.sgiu.exceptions.FiltroInvalidoException.class)
                .hasMessage("El tipo de producto especificado no se vende.");
    }

    @Test
    @org.springframework.security.test.context.support.WithMockUser
    void endpoint_aceptaTipoProductoYRechazaUnoInexistente() throws Exception {
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/dashboard")
                        .param("fechaDesde", "2026-10-01").param("fechaHasta", "2026-10-15")
                        .param("tipoProducto", "REVENTA"))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .jsonPath("$.kpis.ingresosPeriodo").value(18300.0));
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/dashboard")
                        .param("fechaDesde", "2026-10-01").param("fechaHasta", "2026-10-15")
                        .param("tipoProducto", "GOLOSINA"))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
    }

    @Test
    void resultadoDelMes_coincideConLaTablaDeReferencia() {
        ResultadoPeriodoDTO mes = dashboardService.obtenerDashboard(INICIO_MES, HOY, null, null, null)
                .getKpis().getResultado();

        assertThat(mes.ventas()).isEqualByComparingTo("76800");
        assertThat(mes.costoVendido()).isEqualByComparingTo("37905");
        assertThat(mes.gananciaBruta()).isEqualByComparingTo("38895");
        assertThat(mes.margenBrutoPorcentaje()).isEqualByComparingTo("50.64");
        assertThat(mes.otrosIngresos()).isEqualByComparingTo("0");
        // Alquiler + servicios; la compra de chocolate y coco va aparte.
        assertThat(mes.gastos()).isEqualByComparingTo("78000");
        assertThat(mes.comprasMercaderia()).isEqualByComparingTo("45000");
        assertThat(mes.gananciaNeta()).isEqualByComparingTo("-39105");
        assertThat(mes.margenNetoPorcentaje()).isEqualByComparingTo("-50.92");
    }

    @Test
    void resultadoDeLaSemanaYDeHoy() {
        // Semana del lunes 12 al jueves 15.
        ResultadoPeriodoDTO semana = dashboardService.obtenerDashboard(
                LocalDate.of(2026, 10, 12), HOY, null, null, null).getKpis().getResultado();
        assertThat(semana.ventas()).isEqualByComparingTo("63000");
        assertThat(semana.costoVendido()).isEqualByComparingTo("31210");
        assertThat(semana.gananciaBruta()).isEqualByComparingTo("31790");
        assertThat(semana.gastos()).isEqualByComparingTo("18000");
        assertThat(semana.gananciaNeta()).isEqualByComparingTo("13790");

        // Hoy no hubo nada: todo en cero y sin márgenes.
        ResultadoPeriodoDTO hoy = dashboardService.obtenerDashboard(HOY, HOY, null, null, null)
                .getKpis().getResultado();
        assertThat(hoy.ventas()).isEqualByComparingTo("0");
        assertThat(hoy.gananciaNeta()).isEqualByComparingTo("0");
        assertThat(hoy.margenBrutoPorcentaje()).isNull();
        assertThat(hoy.margenNetoPorcentaje()).isNull();
    }

    @Test
    void conMetodoDePago_elCostoDeUnPagoMixtoVaEnProporcion() {
        Long efectivo = datos.metodo("Efectivo").getId();
        ResultadoPeriodoDTO mes = dashboardService.obtenerDashboard(INICIO_MES, HOY, efectivo, null, null)
                .getKpis().getResultado();

        // Ventas 1 y 3 enteras en efectivo; de la 5, 10.000 de 22.700.
        assertThat(mes.ventas()).isEqualByComparingTo("36000");
        // 6.695 + 6.120 + 10.995 × 10.000 / 22.700 (4.843,61).
        assertThat(mes.costoVendido()).isEqualByComparingTo("17658.61");
        assertThat(mes.gastos()).isEqualByComparingTo("18000");
        assertThat(mes.comprasMercaderia()).isEqualByComparingTo("0");
        assertThat(mes.gananciaNeta()).isEqualByComparingTo("341.39");
    }

    @Test
    void otrosIngresosSumanALaGananciaNeta() {
        datos.crearMovimiento(TipoMovimiento.INGRESO, new BigDecimal("5000"), "Efectivo",
                "OTRO_INGRESO", dia(13, 10, 0));

        ResultadoPeriodoDTO mes = dashboardService.obtenerDashboard(INICIO_MES, HOY, null, null, null)
                .getKpis().getResultado();
        assertThat(mes.ventas()).isEqualByComparingTo("76800");
        assertThat(mes.otrosIngresos()).isEqualByComparingTo("5000");
        assertThat(mes.gananciaNeta()).isEqualByComparingTo("-34105");
    }

    @Test
    void ganancias_laGananciaRealEsLaNetaSinRestarLasCompras() {
        BalanceResponseDTO balance = movimientoService.calcularBalance(INICIO_MES, HOY);

        assertThat(balance.totalIngresos()).isEqualByComparingTo("76800");
        assertThat(balance.totalEgresos()).isEqualByComparingTo("123000");
        assertThat(balance.margenNeto()).isEqualByComparingTo("-46200");
        assertThat(balance.costoTotal()).isEqualByComparingTo("37905");
        // Antes: 76.800 − 37.905 − 123.000 = −84.105 (la compra se restaba dos veces).
        assertThat(balance.gananciaReal()).isEqualByComparingTo("-39105");
        assertThat(balance.resultado().gananciaBruta()).isEqualByComparingTo("38895");
    }

    // --- Datos ---

    private static LocalDateTime dia(int dia, int hora, int minuto) {
        return LocalDateTime.of(2026, 10, dia, hora, minuto);
    }

    private EspProducto producto(String codigo, String nombre, String precio, String costo) {
        EspProducto p = datos.crearProducto(codigo, nombre, new BigDecimal(precio), 100, 0);
        p.setPrecioCosto(new BigDecimal(costo));
        return productoRepository.save(p);
    }

    private EspProducto elaborado(EspProducto p) {
        p.setTipo(TipoArticulo.ELABORADO);
        return productoRepository.save(p);
    }

    private void gasto(String categoria, String monto, String metodo, LocalDateTime fecha) {
        datos.crearMovimiento(TipoMovimiento.EGRESO, new BigDecimal(monto), metodo, categoria, fecha);
    }

    /** Una venta con sus líneas (producto, cantidad, ...) y un pago y un movimiento por método. */
    private void vender(LocalDateTime fecha, Map<String, String> pagos, Object... lineas) {
        Venta venta = new Venta();
        venta.setFechaHora(fecha);
        venta.setIdSesionCaja(0);
        venta.setCreadoPorUsuario(0);
        BigDecimal total = BigDecimal.ZERO;
        for (int i = 0; i < lineas.length; i += 2) {
            LineaVenta linea = new LineaVenta(venta, (EspProducto) lineas[i], (Integer) lineas[i + 1]);
            venta.addLinea(linea);
            total = total.add(linea.getSubtotal());
        }
        venta.setTotal(total);
        ventaRepository.save(venta);
        pagos.forEach((metodo, monto) -> {
            PagoVenta pago = pagoRepository.save(new PagoVenta(venta, new BigDecimal(monto), datos.metodo(metodo)));
            movRepository.save(new MovFinanciero(TipoMovimiento.INGRESO, pago.getMonto(), pago.getMetodoPago(),
                    "VENTA", "Venta de productos - ID: " + venta.getId(), fecha, pago));
        });
    }
}
