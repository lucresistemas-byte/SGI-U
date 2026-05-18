package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final EspProductoRepository productoRepository;
    
    // 1. NUEVO: Agregamos el repositorio de stock acá abajo del otro
    private final com.sgiu_group.sgiu.repositories.ArticuloStockRepository stockRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return productoRepository.obtenerCatalogo();
    }

    // 2. NUEVO: Agregamos todo el método de crearProducto justo debajo de la llave que cierra getCatalogo()
    @Transactional
    public ProductoCatalogoDTO crearProducto(com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO dto) {
        if (productoRepository.existsByCodigo(dto.codigo())) {
            throw new IllegalArgumentException("El código de producto '" + dto.codigo() + "' ya existe.");
        }

        com.sgiu_group.sgiu.models.entities.EspProducto nuevoProducto = 
            new com.sgiu_group.sgiu.models.entities.EspProducto(dto.codigo(), dto.nombre(), dto.precioUnitario());
        
        if (dto.activo() != null) {
            nuevoProducto.setActivo(dto.activo());
        }
        productoRepository.save(nuevoProducto);

        com.sgiu_group.sgiu.models.entities.ArticuloStock nuevoStock = new com.sgiu_group.sgiu.models.entities.ArticuloStock();
        nuevoStock.setEspProducto(nuevoProducto);
        nuevoStock.setCantidad(dto.stockActual() != null ? dto.stockActual() : 0L);
        stockRepository.save(nuevoStock);

        return new ProductoCatalogoDTO(
                nuevoProducto.getCodigo(),
                nuevoProducto.getNombre(),
                nuevoProducto.getPrecioUnitario(),
                nuevoStock.getCantidad(),
                nuevoProducto.isActivo()
        );
    }
}