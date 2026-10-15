package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.models.dtos.dashboard.ProductoGananciaDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.LineaVenta;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import com.sgiu_group.sgiu.services.DashboardService;
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

    private EspProducto tarta, torta, alfajor, coca, agua, bombones;

    @BeforeEach
    void demo() {
        limpiarBaseDatos();
        tarta = producto("ELA-0001", "Tarta de coco", "10800", "4895");
        torta = producto("ELA-0002", "Torta de chocolate", "21200", "10095");
        alfajor = producto("ELA-0003", "Alfajor de maicena", "5300", "2120");
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
    void loQueMasPlataTeDeja_top5PorGananciaEnPesos() {
        DashboardResponseDTO mes = dashboardService.obtenerDashboard(INICIO_MES, HOY, null, null, null);

        assertThat(mes.getGraficos().getTopProductosPorGanancia())
                .extracting(ProductoGananciaDTO::nombre)
                // El agua (ganancia 800) queda afuera; la Coca-Cola, que es la
                // que más unidades vendió, es la quinta.
                .containsExactly("Torta de chocolate", "Tarta de coco", "Caja de bombones 100 g",
                        "Alfajor de maicena", "Coca-Cola 500 ml");
        ProductoGananciaDTO primero = mes.getGraficos().getTopProductosPorGanancia().getFirst();
        assertThat(primero.cantidadVendida()).isEqualTo(2L);
        assertThat(primero.ventas()).isEqualByComparingTo("42400");
        assertThat(primero.costo()).isEqualByComparingTo("20190");
        assertThat(primero.ganancia()).isEqualByComparingTo("22210");
        ProductoGananciaDTO coca = mes.getGraficos().getTopProductosPorGanancia().getLast();
        assertThat(coca.cantidadVendida()).isEqualTo(3L);
        assertThat(coca.ganancia()).isEqualByComparingTo("1800");
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
