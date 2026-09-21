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

    @InjectMocks
    private VentaService ventaService;

    private ArticuloStock stockDe(Double precio, int cantidad) {
        EspProducto producto = new EspProducto("P1", "Producto Uno", new BigDecimal(precio.toString()));
        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(cantidad);
        return stock;
    }

    @Test
    void procesarVenta_productoInexistente_lanzaExcepcionYNoPersisteNada() {
        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.empty());

        VentaRequestDTO request = new VentaRequestDTO(1L, List.of(new LineaVentaDTO("P1", 2)));

        assertThatThrownBy(() -> ventaService.procesarVenta(request))
                .isInstanceOf(ProductoNoEncontradoException.class)
                .hasMessage("Producto no encontrado: P1");

        verify(ventaRepository, never()).save(any());
        verify(pagoRepository, never()).save(any());
        verify(movFinancieroRepository, never()).save(any());
    }

    @Test
    void procesarVenta_stockInsuficiente_lanzaExcepcionYNoDescuenta() {
        ArticuloStock stock = stockDe(10.00, 5);
        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stock));

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("P1", 10)));

        assertThatThrownBy(() -> ventaService.procesarVenta(request))
                .isInstanceOf(StockInsuficienteException.class)
                .hasMessage("Stock insuficiente para: P1");

        assertThat(stock.getCantidad()).isEqualTo(5);
        verify(stockRepository, never()).save(any());
        verify(ventaRepository, never()).save(any());
    }

    @Test
    void procesarVenta_valida_descuentaStockRegistraVentaPagoYMovimiento() {
        ArticuloStock stock = stockDe(10.50, 5);
        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stock));
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> {
            Venta venta = inv.getArgument(0);
            ReflectionTestUtils.setField(venta, "id", 7L);
            return venta;
        });

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(new LineaVentaDTO("P1", 2)));
        ventaService.procesarVenta(request);

        // El stock se descuenta de 5 a 3
        assertThat(stock.getCantidad()).isEqualTo(3);
        verify(stockRepository).save(stock);

        // La venta se guarda con el total calculado (10.50 * 2 = 21.00)
        ArgumentCaptor<Venta> ventaCaptor = ArgumentCaptor.forClass(Venta.class);
        verify(ventaRepository).save(ventaCaptor.capture());
        Venta ventaGuardada = ventaCaptor.getValue();
        assertThat(ventaGuardada.getTotal()).isEqualByComparingTo("21.00");
        assertThat(ventaGuardada.getLineas()).hasSize(1);

        // Se registra el pago con el método del request
        ArgumentCaptor<PagoVenta> pagoCaptor = ArgumentCaptor.forClass(PagoVenta.class);
        verify(pagoRepository).save(pagoCaptor.capture());
        assertThat(pagoCaptor.getValue().getMonto()).isEqualByComparingTo("21.00");
        assertThat(pagoCaptor.getValue().getMetodo()).isEqualTo("EFECTIVO");

        // Se registra el movimiento financiero de tipo INGRESO
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
        stockB.setCantidad(20);

        when(stockRepository.findByEspProducto_Codigo("P1")).thenReturn(Optional.of(stockA));
        when(stockRepository.findByEspProducto_Codigo("P2")).thenReturn(Optional.of(stockB));
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> inv.getArgument(0));

        VentaRequestDTO request = new VentaRequestDTO(null, List.of(
                new LineaVentaDTO("P1", 3),
                new LineaVentaDTO("P2", 4)));

        ventaService.procesarVenta(request);

        ArgumentCaptor<Venta> ventaCaptor = ArgumentCaptor.forClass(Venta.class);
        verify(ventaRepository).save(ventaCaptor.capture());
        // 10.00 * 3 + 5.00 * 4 = 50.00
        assertThat(ventaCaptor.getValue().getTotal()).isEqualByComparingTo("50.00");
        assertThat(ventaCaptor.getValue().getLineas()).hasSize(2);
    }
}