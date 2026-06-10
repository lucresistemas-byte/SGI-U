package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.StockRequestDTO;
import com.sgiu_group.sgiu.services.ProductoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

    @GetMapping
    public ResponseEntity<List<ProductoCatalogoDTO>> listarProductos() {
        return ResponseEntity.ok(productoService.getCatalogo());
    }

    @PostMapping("/crear")
    public ResponseEntity<?> crearProducto(@Valid @RequestBody ProductoRequestDTO dto) {
        try {
            ProductoCatalogoDTO nuevoProducto = productoService.crearProducto(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(nuevoProducto);
        } catch (IllegalArgumentException e) {
            String mensaje = e.getMessage();
            if (mensaje.contains("código") || mensaje.contains("existe")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", mensaje));
            }
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(Map.of("error", mensaje));
        }
    }

    @PutMapping("/editar/{codigo}")
    public ResponseEntity<?> actualizarProducto(
            @PathVariable String codigo,
            @Valid @RequestBody ProductoRequestDTO dto) {
        try {
            ProductoCatalogoDTO productoActualizado = productoService.actualizarProducto(codigo, dto);
            return ResponseEntity.ok(productoActualizado);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/stock/{codigo}")
    public ResponseEntity<?> ajustarStock(
            @PathVariable String codigo,
            @Valid @RequestBody StockRequestDTO request) {
        try {
            ProductoCatalogoDTO resultado = productoService.ajustarStock(codigo, request.cantidad());
            return ResponseEntity.ok(resultado);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(Map.of("error", e.getMessage()));
        }
    }
}
