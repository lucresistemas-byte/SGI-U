package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.services.VentaService;
import jakarta.validation.Valid; 
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/ventas")
public class VentaController {

    @Autowired
    private VentaService ventaService;

    /** Los errores (producto inexistente, stock insuficiente, validación) los
     *  responde GlobalExceptionHandler en JSON: {"error": "..."}. */
    @PostMapping
    public ResponseEntity<Void> crearVenta(@Valid @RequestBody VentaRequestDTO request) {
        ventaService.procesarVenta(request);
        return ResponseEntity.status(HttpStatus.CREATED).build(); // 201 Created
    }
}
