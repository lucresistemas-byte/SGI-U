package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.ProductoNoEncontradoException;
import com.sgiu_group.sgiu.exceptions.StockInsuficienteException;
import com.sgiu_group.sgiu.models.dtos.LineaVentaDTO;
import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import com.sgiu_group.sgiu.repositories.PagoVentaRepository;
import com.sgiu_group.sgiu.repositories.VentaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VentaServiceTest {

    @Mock
    private VentaRepository ventaRepository;
    @Mock
    private ArticuloStockRepository stockRepository;
    @Mock
    private PagoVentaRepository pagoRepository;
    @Mock
    private MovFinancieroRepository movFinancieroRepository;
    @Mock
    private MetodoPagoService metodoPagoService;
    @Mock
    private com.sgiu_group.sgiu.repositories.MovimientoStockRepository movimientoRepository;

    @org.junit.jupiter.api.BeforeEach
    void efectivo() {
        ReflectionTestUtils.setField(ventaService, "stockService", new StockService(stockRepository, movimientoRepository));
        org.mockito.Mockito.lenient().when(metodoPagoService.efectivo())
                .thenReturn(new com.sgiu_group.sgiu.models.entities.MetodoPago("Efectivo", true, 1));
    }

    @InjectMocks
    private VentaService ventaService;

    private ArticuloStock stockDe(Double precio, int cantidad) {
        EspProducto producto = new EspProducto("P1", "Producto Uno", new BigDecimal(precio.toString()));
        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(BigDecimal.valueOf(cantidad));
        return stock;
    }

    @Test
    void procesarVenta_productoNoEncontrado_lanzaExcepcion() {
        when(stockRepository.findByEspProducto_Codigo("NO_EXISTE")).thenReturn(Optional.empty());

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("NO_EXISTE", 1)));

        assertThatThrownBy(() -> ventaService.procesarVenta(request))
                .isInstanceOf(ProductoNoEncontradoException.class)
                .hasMessageContaining("NO_EXISTE");
    }

    @Test
    void procesarVenta_stockInsuficiente_lanzaExcepcion() {
        ArticuloStock stock = stockDe(10.00, 3);
        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stock));

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("P1", 5)));

        assertThatThrownBy(() -> ventaService.procesarVenta(request))
                .isInstanceOf(StockInsuficienteException.class)
                .hasMessageContaining("Stock insuficiente");
    }

    @Test
    void procesarVenta_exitosa_guardaVentaYDescuentaStock() {
        ArticuloStock stock = stockDe(10.00, 10);
        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stock));
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> {
            Venta v = inv.getArgument(0);
            ReflectionTestUtils.setField(v, "id", 42L);
            return v;
        });

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("P1", 2)));

        ventaService.procesarVenta(request);

        ArgumentCaptor<Venta> ventaCaptor = ArgumentCaptor.forClass(Venta.class);
        verify(ventaRepository).save(ventaCaptor.capture());
        Venta guardada = ventaCaptor.getValue();
        assertThat(guardada.getTotal()).isEqualByComparingTo("20.00");
        assertThat(guardada.getLineas()).hasSize(1);
        assertThat(guardada.getLineas().get(0).getCantidad()).isEqualTo(2);

        assertThat(stock.getCantidad()).isEqualByComparingTo("8");
    }

    @Test
    void procesarVenta_exitosa_registraPagoYMovimientoFinanciero() {
        ArticuloStock stock = stockDe(7.00, 10);
        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stock));
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> {
            Venta v = inv.getArgument(0);
            ReflectionTestUtils.setField(v, "id", 7L);
            return v;
        });
        when(pagoRepository.save(any(PagoVenta.class))).thenAnswer(inv -> inv.getArgument(0));

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("P1", 3)));

        ventaService.procesarVenta(request);

        ArgumentCaptor<PagoVenta> pagoCaptor = ArgumentCaptor.forClass(PagoVenta.class);
        verify(pagoRepository).save(pagoCaptor.capture());
        assertThat(pagoCaptor.getValue().getMonto()).isEqualByComparingTo("21.00");
        assertThat(pagoCaptor.getValue().getMetodoPago().getNombre()).isEqualTo("Efectivo");

        ArgumentCaptor<MovFinanciero> movCaptor = ArgumentCaptor.forClass(MovFinanciero.class);
        verify(movFinancieroRepository).save(movCaptor.capture());
        MovFinanciero mov = movCaptor.getValue();
        assertThat(mov.getTipo()).isEqualTo(TipoMovimiento.INGRESO);
        assertThat(mov.getMonto()).isEqualByComparingTo("21.00");
        assertThat(mov.getCategoria()).isEqualTo("VENTA");
        assertThat(mov.getDescripcion()).contains("Venta de productos - ID: 7");
        assertThat(mov.getPago()).isSameAs(pagoCaptor.getValue());
    }

    @Test
    void procesarVenta_multipleLineas_acumulaTotal() {
        ArticuloStock stockA = stockDe(10.00, 10);
        EspProducto productoB = new EspProducto("P2", "Producto Dos", new BigDecimal("5.00"));
        ArticuloStock stockB = new ArticuloStock();
        stockB.setEspProducto(productoB);
        stockB.setCantidad(BigDecimal.valueOf(20));

        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stockA));
        when(stockRepository.findByEspProducto_Codigo("P2")).thenReturn(Optional.of(stockB));
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> inv.getArgument(0));

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(
                new LineaVentaDTO("P1", 3),
                new LineaVentaDTO("P2", 4)));

        ventaService.procesarVenta(request);

        ArgumentCaptor<Venta> ventaCaptor = ArgumentCaptor.forClass(Venta.class);
        verify(ventaRepository).save(ventaCaptor.capture());
        assertThat(ventaCaptor.getValue().getTotal()).isEqualByComparingTo("50.00");
        assertThat(ventaCaptor.getValue().getLineas()).hasSize(2);
    }

    @Test
    void procesarVenta_mismoTokenIdempotencia_retornaMismaVentaSinDuplicar() {
        String token = "uuid-token-12345";
        Venta ventaExistente = new Venta();
        ReflectionTestUtils.setField(ventaExistente, "id", 99L);
        ventaExistente.setTotal(new BigDecimal("100.00"));
        ventaExistente.setTokenIdempotencia(token);

        when(ventaRepository.findByTokenIdempotencia(token)).thenReturn(Optional.of(ventaExistente));
        when(pagoRepository.findByVenta(ventaExistente)).thenReturn(List.of());

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("P1", 2)), null, token);

        var respuesta = ventaService.procesarVenta(request);

        assertThat(respuesta.id()).isEqualTo(99L);
        assertThat(respuesta.total()).isEqualByComparingTo("100.00");
        verify(ventaRepository, never()).save(any(Venta.class));
        verify(stockRepository, never()).findByEspProducto_Codigo(any());
    }
}
