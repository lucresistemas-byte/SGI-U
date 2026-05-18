package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final EspProductoRepository productoRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return productoRepository.obtenerCatalogo();
    }

    @Transactional
    public ProductoCatalogoDTO crearProducto(ProductoCatalogoDTO dto) {
        EspProducto nuevoProducto = new EspProducto();
        
        // ¡Magia de los records! Se llaman como la variable, sin el "get"
        nuevoProducto.setCodigo(dto.codigo());
        nuevoProducto.setNombre(dto.nombre());
        nuevoProducto.setPrecioUnitario(dto.precioUnitario());
        // No seteamos stock porque EspProducto no lleva stock
        // No seteamos activo porque el constructor de EspProducto ya lo pone en true

        productoRepository.save(nuevoProducto);

        // Devolvemos el record inmutable
        return new ProductoCatalogoDTO(
            dto.codigo(), dto.nombre(), dto.precioUnitario(), 0L, true
        );
    }

    @Transactional
    public ProductoCatalogoDTO actualizarProducto(String codigo, ProductoCatalogoDTO dto) {
        // Usamos nuestro método nuevo findByCodigo
        EspProducto productoExistente = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new RuntimeException("Error: Producto no encontrado con código " + codigo));

        productoExistente.setNombre(dto.nombre());
        productoExistente.setPrecioUnitario(dto.precioUnitario());
        productoExistente.setActivo(dto.activo()); // Toggle de la baja lógica

        productoRepository.save(productoExistente);

        return new ProductoCatalogoDTO(
            codigo, dto.nombre(), dto.precioUnitario(), dto.stockActual(), dto.activo()
        );
    }
}