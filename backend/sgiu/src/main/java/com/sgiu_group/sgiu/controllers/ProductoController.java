package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
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

    // 1. LISTAR (endpoint existente)
    @GetMapping
    public ResponseEntity<List<ProductoCatalogoDTO>> listarProductos() {
        return ResponseEntity.ok(productoService.getCatalogo());
    }

    // 2. CREAR (nuevo endpoint BK-5)
    @PostMapping("/crear")
    public ResponseEntity<?> crearProducto(@RequestBody ProductoRequestDTO dto) {
        try {
            ProductoCatalogoDTO nuevoProducto = productoService.crearProducto(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(nuevoProducto);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(e.getMessage());
        }
    }

    // 3. ACTUALIZAR (nuevo endpoint BK-6)
    @PutMapping("/editar/{codigo}")
    public ResponseEntity<?> actualizarProducto(
            @PathVariable String codigo,
            @RequestBody ProductoRequestDTO dto) {
        try {
            ProductoCatalogoDTO productoActualizado = productoService.actualizarProducto(codigo, dto);
            return ResponseEntity.ok(productoActualizado);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}