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
<<<<<<< HEAD
    
=======
     
>>>>>>> b8680ed (feat: agregar login)
    // 1. NUEVO: Agregamos el repositorio de stock acá abajo del otro
    private final com.sgiu_group.sgiu.repositories.ArticuloStockRepository stockRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return productoRepository.obtenerCatalogo();
    }

<<<<<<< HEAD
<<<<<<< HEAD
    // 2. NUEVO: Agregamos todo el método de crearProducto justo debajo de la llave que cierra getCatalogo()
=======
>>>>>>> b8680ed (feat: agregar login)
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
        // SOLUCIÓN: Convertimos el Long del DTO al Integer de la Entidad
        nuevoStock.setCantidad(dto.stockActual() != null ? dto.stockActual().intValue() : 0);
        stockRepository.save(nuevoStock);

        return new ProductoCatalogoDTO(
                nuevoProducto.getCodigo(),
                nuevoProducto.getNombre(),
                nuevoProducto.getPrecioUnitario(),
                // SOLUCIÓN: Convertimos el Integer de la Entidad al Long del DTO
                Long.valueOf(nuevoStock.getCantidad()),
                nuevoProducto.isActivo()
<<<<<<< HEAD
=======
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
>>>>>>> origin/iteracion-2-frontend
=======
>>>>>>> b8680ed (feat: agregar login)
        );
    }

    @Transactional
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> b8680ed (feat: agregar login)
    public ProductoCatalogoDTO actualizarProducto(String codigo, com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO dto) {
        com.sgiu_group.sgiu.models.entities.EspProducto productoExistente = productoRepository.findByCodigo(codigo)
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

        // SOLUCIÓN: Traducimos el Integer a Long al buscar en la BD
        Long stockActual = stockRepository.findByEspProducto(productoExistente)
                .map(stock -> Long.valueOf(stock.getCantidad()))
                .orElse(0L);

        return new ProductoCatalogoDTO(
                productoExistente.getCodigo(),
                productoExistente.getNombre(),
                productoExistente.getPrecioUnitario(),
                stockActual,
                productoExistente.isActivo()
<<<<<<< HEAD
=======
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
>>>>>>> origin/iteracion-2-frontend
=======
>>>>>>> b8680ed (feat: agregar login)
        );
    }
}