package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoResponseDTO;
import com.sgiu_group.sgiu.services.MovimientoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/movimientos")
public class MovimientoController {

    private final MovimientoService movimientoService;

    public MovimientoController(MovimientoService movimientoService) {
        this.movimientoService = movimientoService;
    }

    @PostMapping
    public ResponseEntity<?> crearMovimiento(@Valid @RequestBody MovimientoRequestDTO dto) {
        try {
            MovimientoResponseDTO response = movimientoService.crearMovimiento(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<List<MovimientoResponseDTO>> listarMovimientos() {
        return ResponseEntity.ok(movimientoService.listarMovimientos());
    }
}
