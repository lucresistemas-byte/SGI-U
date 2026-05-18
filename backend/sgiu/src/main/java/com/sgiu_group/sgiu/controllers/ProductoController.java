package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.services.ProductoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

    // 1. LISTAR (El que ya tenías)
    @GetMapping
    public ResponseEntity<List<ProductoCatalogoDTO>> listarProductos() {
        return ResponseEntity.ok(productoService.getCatalogo()); // Cambiá getCatalogo() si tu método se llama distinto
    }

    // 2. CREAR (NUEVO)
    @PostMapping
    public ResponseEntity<ProductoCatalogoDTO> crearProducto(@RequestBody ProductoCatalogoDTO productoDTO) {
        ProductoCatalogoDTO nuevoProducto = productoService.crearProducto(productoDTO); // Cambiá crearProducto si tu método se llama distinto
        return ResponseEntity.status(HttpStatus.CREATED).body(nuevoProducto);
    }

    // 3. ACTUALIZAR / ARCHIVAR (NUEVO)
    @PutMapping("/{codigo}")
    public ResponseEntity<ProductoCatalogoDTO> actualizarProducto(
            @PathVariable String codigo, 
            @RequestBody ProductoCatalogoDTO productoDTO) {
        ProductoCatalogoDTO productoActualizado = productoService.actualizarProducto(codigo, productoDTO); // Cambiá actualizarProducto si tu método se llama distinto
        return ResponseEntity.ok(productoActualizado);
    }
}