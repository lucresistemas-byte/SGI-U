package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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
class ProductoServiceTest {

    @Mock
    private EspProductoRepository productoRepository;
    @Mock
    private ArticuloStockRepository stockRepository;

    @InjectMocks
    private ProductoService productoService;

    @Test
    void getCatalogo_delegaEnElRepositorio() {
        ProductoCatalogoDTO dto = new ProductoCatalogoDTO(
                "P1", "Producto Uno", new BigDecimal("10.50"), 8L, 2, true);
        when(productoRepository.obtenerCatalogo()).thenReturn(List.of(dto));

        List<ProductoCatalogoDTO> catalogo = productoService.getCatalogo();

        assertThat(catalogo).extracting(ProductoCatalogoDTO::codigo).containsExactly("P1");
    }

    @Test
    void crearProducto_sinPrecio_lanzaExcepcion() {
        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "Sin Precio", null, 1L, 0, true);

        assertThatThrownBy(() -> productoService.crearProducto(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("El precio es obligatorio.");

        verify(productoRepository, never()).existsByCodigo(any());
    }

    @Test
    void crearProducto_stockNegativo_lanzaExcepcion() {
        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "Sin Stock", new BigDecimal("10.00"), -1L, 0, true);

        assertThatThrownBy(() -> productoService.crearProducto(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("El stock no puede ser negativo.");
    }

    @Test
    void crearProducto_codigoDuplicado_lanzaExcepcion() {
        when(productoRepository.existsByCodigo("P1")).thenReturn(true);
        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "Duplicado", new BigDecimal("10.00"), 1L, 0, true);

        assertThatThrownBy(() -> productoService.crearProducto(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("El código de producto ya existe.");

        verify(productoRepository, never()).save(any());
    }

    @Test
    void crearProducto_valido_guardaProductoYStock() {
        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "Nuevo", new BigDecimal("15.00"), 5L, 3, false);

        ProductoCatalogoDTO resultado = productoService.crearProducto(dto);

        assertThat(resultado.codigo()).isEqualTo("P1");
        assertThat(resultado.nombre()).isEqualTo("Nuevo");
        assertThat(resultado.precioUnitario()).isEqualByComparingTo("15.00");
        assertThat(resultado.stockActual()).isEqualTo(5L);
        assertThat(resultado.stockMinimo()).isEqualTo(3);
        assertThat(resultado.activo()).isFalse();

        verify(productoRepository).save(any(EspProducto.class));
        verify(stockRepository).save(any(ArticuloStock.class));
    }

    @Test
    void crearProducto_sinStockInicial_stockEnCero () {
        ProductoRequestDTO dto = new ProductoRequestDTO("P2", "Sin Stock", new BigDecimal("20.00"), null, null, null);

        ProductoCatalogoDTO resultado = productoService.crearProducto(dto);

        assertThat(resultado.stockActual()).isEqualTo(0L);
        assertThat(resultado.stockMinimo()).isZero();
        assertThat(resultado.activo()).isTrue();
    }

    @Test
    void actualizarProducto_inexistente_lanzaExcepcion() {
        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.empty());
        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "X", new BigDecimal("10.00"), null, null, null);

        assertThatThrownBy(() -> productoService.actualizarProducto("P1", dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No se encontró un producto con el código: P1");
    }

    @Test
    void actualizarProducto_precioInvalido_lanzaExcepcion() {
        EspProducto producto = new EspProducto("P1", "Viejo", new BigDecimal("10.00"));
        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.of(producto));
        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "X", new BigDecimal("0.005"), null, null, null);

        assertThatThrownBy(() -> productoService.actualizarProducto("P1", dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("El precio debe ser un valor mayor a $0.");
    }

    @Test
    void actualizarProducto_valido_actualizaDatos() {
        EspProducto producto = new EspProducto("P1", "Viejo", new BigDecimal("10.00"));
        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(4);
        stock.setStockMinimo(1);

        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.of(producto));
        when(stockRepository.findByEspProducto(producto)).thenReturn(Optional.of(stock));

        ProductoRequestDTO dto = new ProductoRequestDTO("P1", "Nuevo Nombre", new BigDecimal("12.00"), null, 5, true);

        ProductoCatalogoDTO resultado = productoService.actualizarProducto("P1", dto);

        assertThat(producto.getNombre()).isEqualTo("Nuevo Nombre");
        assertThat(producto.getPrecioUnitario()).isEqualByComparingTo("12.00");
        assertThat(producto.isActivo()).isTrue();
        assertThat(stock.getStockMinimo()).isEqualTo(5);
        assertThat(resultado.stockActual()).isEqualTo(4L);
        verify(stockRepository).save(stock);
    }

    @Test
    void ajustarStock_inexistente_lanzaExcepcion() {
        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> productoService.ajustarStock("P1", 5))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No se encontró un producto con el código: P1");
    }

    @Test
    void ajustarStock_resultadoNegativo_lanzaExcepcion() {
        EspProducto producto = new EspProducto("P1", "Viejo", new BigDecimal("10.00"));
        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(2);

        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.of(producto));
        when(stockRepository.findByEspProducto(producto)).thenReturn(Optional.of(stock));

        assertThatThrownBy(() -> productoService.ajustarStock("P1", -5))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("El stock no puede quedar negativo.");

        assertThat(stock.getCantidad()).isEqualTo(2);
        verify(stockRepository, never()).save(any());
    }

    @Test
    void ajustarStock_valido_modificaCantidad() {
        EspProducto producto = new EspProducto("P1", "Viejo", new BigDecimal("10.00"));
        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(2);

        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.of(producto));
        when(stockRepository.findByEspProducto(producto)).thenReturn(Optional.of(stock));

        ProductoCatalogoDTO resultado = productoService.ajustarStock("P1", 3);

        assertThat(stock.getCantidad()).isEqualTo(5);
        assertThat(resultado.stockActual()).isEqualTo(5L);
        verify(stockRepository).save(stock);
    }

    @Test
    void ajustarStock_sinRegistroDeStock_loCreaEnCero() {
        EspProducto producto = new EspProducto("P1", "Viejo", new BigDecimal("10.00"));
        when(productoRepository.findByCodigo("P1")).thenReturn(Optional.of(producto));
        when(stockRepository.findByEspProducto(producto)).thenReturn(Optional.empty());

        ProductoCatalogoDTO resultado = productoService.ajustarStock("P1", 4);

        assertThat(resultado.stockActual()).isEqualTo(4L);
        verify(stockRepository).save(any(ArticuloStock.class));
    }
}