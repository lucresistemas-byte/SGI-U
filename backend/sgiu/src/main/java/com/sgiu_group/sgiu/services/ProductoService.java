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
        if (productoRepository.existsByCodigo(dto.codigo())) {
            throw new IllegalArgumentException("El código de producto '" + dto.codigo() + "' ya existe.");
        }

        EspProducto nuevoProducto = new EspProducto(dto.codigo(), dto.nombre(), dto.precioUnitario());
        if (dto.activo() != null) {
            nuevoProducto.setActivo(dto.activo());
        }
        productoRepository.save(nuevoProducto);

        ArticuloStock nuevoStock = new ArticuloStock();
        nuevoStock.setEspProducto(nuevoProducto);
        nuevoStock.setCantidad(dto.stockActual() != null ? dto.stockActual().intValue() : 0);
        stockRepository.save(nuevoStock);

        return new ProductoCatalogoDTO(
                nuevoProducto.getCodigo(),
                nuevoProducto.getNombre(),
                nuevoProducto.getPrecioUnitario(),
                Long.valueOf(nuevoStock.getCantidad()),
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
            productoExistente.setPrecioUnitario(dto.precioUnitario());
        }
        if (dto.activo() != null) {
            productoExistente.setActivo(dto.activo());
        }

        productoRepository.save(productoExistente);

        Long stockActual = stockRepository.findByEspProducto(productoExistente)
                .map(stock -> Long.valueOf(stock.getCantidad()))
                .orElse(0L);

        return new ProductoCatalogoDTO(
                productoExistente.getCodigo(),
                productoExistente.getNombre(),
                productoExistente.getPrecioUnitario(),
                stockActual,
                productoExistente.isActivo()
        );
    }
}