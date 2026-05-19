package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.services.ProductoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
<<<<<<< HEAD
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CrossOrigin;
=======
import org.springframework.web.bind.annotation.*;
>>>>>>> origin/iteracion-2-frontend

import java.util.List;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

<<<<<<< HEAD
    // Este es el endpoint que ya tenías (BK-7)
=======
    // 1. LISTAR (El que ya tenías)
>>>>>>> origin/iteracion-2-frontend
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

    // NUEVO: Endpoint PUT para editar un producto específico (BK-6)
    @org.springframework.web.bind.annotation.PutMapping("/{codigo}")
    public ResponseEntity<?> actualizarProducto(
            @org.springframework.web.bind.annotation.PathVariable String codigo,
            @org.springframework.web.bind.annotation.RequestBody com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO dto) {
        try {
            // Mandamos los datos al servicio
            ProductoCatalogoDTO productoActualizado = productoService.actualizarProducto(codigo, dto);
            // Si todo va bien, devolvemos un 200 (OK) con el producto modificado
            return ResponseEntity.ok(productoActualizado);
        } catch (IllegalArgumentException e) {
            // Si el servicio no encontró el código, devolvemos un 404 (Not Found)
            return ResponseEntity.status(org.springframework.http.HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}