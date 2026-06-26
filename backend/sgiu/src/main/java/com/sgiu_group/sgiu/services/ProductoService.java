package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final EspProductoRepository productoRepository;

    // Repositorio para manejar el stock
    private final ArticuloStockRepository stockRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return productoRepository.obtenerCatalogo();
    }

    @Transactional
    public ProductoCatalogoDTO crearProducto(ProductoRequestDTO dto) {
        if (dto.precioUnitario() == null) {
            throw new IllegalArgumentException("El precio es obligatorio.");
        }
        if (dto.stockActual() != null && dto.stockActual() < 0) {
            throw new IllegalArgumentException("El stock no puede ser negativo.");
        }
        if (productoRepository.existsByCodigo(dto.codigo())) {
            throw new IllegalArgumentException("El código de producto ya existe.");
        }

        EspProducto nuevoProducto = new EspProducto(dto.codigo(), dto.nombre(), dto.precioUnitario());
        if (dto.activo() != null) {
            nuevoProducto.setActivo(dto.activo());
        }
        productoRepository.save(nuevoProducto);

        ArticuloStock nuevoStock = new ArticuloStock();
        nuevoStock.setEspProducto(nuevoProducto);
        nuevoStock.setCantidad(dto.stockActual() != null ? dto.stockActual().intValue() : 0);
        nuevoStock.setStockMinimo(dto.stockMinimo() != null ? dto.stockMinimo() : 0);
        stockRepository.save(nuevoStock);

        return new ProductoCatalogoDTO(
                nuevoProducto.getCodigo(),
                nuevoProducto.getNombre(),
                nuevoProducto.getPrecioUnitario(),
                Long.valueOf(nuevoStock.getCantidad()),
                nuevoStock.getStockMinimo(),
                nuevoProducto.isActivo()
        );
    }

    @Transactional
    public ProductoCatalogoDTO actualizarProducto(String codigo, ProductoRequestDTO dto) {
        EspProducto productoExistente = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));

        if (dto.nombre() != null) {
            productoExistente.setNombre(dto.nombre());
        }
        if (dto.precioUnitario() != null) {
            if (dto.precioUnitario().compareTo(new java.math.BigDecimal("0.01")) < 0) {
                throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
            }
            productoExistente.setPrecioUnitario(dto.precioUnitario());
        }
        if (dto.activo() != null) {
            productoExistente.setActivo(dto.activo());
        }

        productoRepository.save(productoExistente);

        ArticuloStock stock = stockRepository.findByEspProducto(productoExistente)
                .orElseGet(() -> {
                    ArticuloStock nuevo = new ArticuloStock();
                    nuevo.setEspProducto(productoExistente);
                    nuevo.setCantidad(0);
                    nuevo.setStockMinimo(0);
                    return nuevo;
                });

        if (dto.stockMinimo() != null) {
            stock.setStockMinimo(dto.stockMinimo());
            stockRepository.save(stock);
        }

        return new ProductoCatalogoDTO(
                productoExistente.getCodigo(),
                productoExistente.getNombre(),
                productoExistente.getPrecioUnitario(),
                Long.valueOf(stock.getCantidad()),
                stock.getStockMinimo(),
                productoExistente.isActivo()
        );
    }

    @Transactional
    public ProductoCatalogoDTO ajustarStock(String codigo, Integer cantidad) {
        EspProducto producto = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));

        ArticuloStock stock = stockRepository.findByEspProducto(producto)
                .orElseGet(() -> {
                    ArticuloStock nuevo = new ArticuloStock();
                    nuevo.setEspProducto(producto);
                    nuevo.setCantidad(0);
                    return nuevo;
                });

        int nuevoStock = stock.getCantidad() + cantidad;
        if (nuevoStock < 0) {
            throw new IllegalArgumentException("El stock no puede quedar negativo.");
        }

        stock.setCantidad(nuevoStock);
        stockRepository.save(stock);

        return new ProductoCatalogoDTO(
                producto.getCodigo(),
                producto.getNombre(),
                producto.getPrecioUnitario(),
                Long.valueOf(nuevoStock),
                stock.getStockMinimo(),
                producto.isActivo()
        );
    }
}