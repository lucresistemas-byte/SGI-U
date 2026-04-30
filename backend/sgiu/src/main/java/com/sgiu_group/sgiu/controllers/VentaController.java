package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.exceptions.ProductoNoEncontradoException;
import com.sgiu_group.sgiu.exceptions.StockInsuficienteException;
import com.sgiu_group.sgiu.services.VentaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/ventas")
public class VentaController {

    @Autowired
    private VentaService ventaService;

    @PostMapping
    public ResponseEntity<?> crearVenta(@RequestBody VentaRequestDTO request) {
        try {
            ventaService.procesarVenta(request);
            return ResponseEntity.status(HttpStatus.CREATED).build(); // 201 Created
        } catch (ProductoNoEncontradoException e) {
            // 404 Not Found - Recurso no existe
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (StockInsuficienteException e) {
            // 400 Bad Request - Error de regla de negocio
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            // 500 Internal Server Error - Error inesperado
            // En producción, se debería logar el error completo y devolver un mensaje genérico
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error interno del servidor");
        }
    }
}