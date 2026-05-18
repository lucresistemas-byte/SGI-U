package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.services.ProductoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CrossOrigin;

import java.util.List;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

    // Este es el endpoint que ya tenías (BK-7)
    @GetMapping
    public ResponseEntity<List<ProductoCatalogoDTO>> listarProductos() {
        return ResponseEntity.ok(productoService.getCatalogo());
    }

    // Este es el NUEVO endpoint que agregamos (BK-5)
    @PostMapping
    public ResponseEntity<?> crearProducto(@RequestBody ProductoRequestDTO dto) {
        try {
            // Llama al servicio que armamos en el paso anterior
            ProductoCatalogoDTO nuevoProducto = productoService.crearProducto(dto);
            // Devuelve un código 201 (Created) si todo salió perfecto
            return ResponseEntity.status(HttpStatus.CREATED).body(nuevoProducto);
        } catch (IllegalArgumentException e) {
            // Devuelve un código 409 (Conflict) si el código de producto ya existe
            return ResponseEntity.status(HttpStatus.CONFLICT).body(e.getMessage());
        }
    }
}