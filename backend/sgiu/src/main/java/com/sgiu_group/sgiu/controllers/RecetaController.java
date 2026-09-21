package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.RecetaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaResponseDTO;
import com.sgiu_group.sgiu.services.RecetaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recetas")
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService recetaService;

    @GetMapping
    public ResponseEntity<List<RecetaResponseDTO>> listarTodas() {
        return ResponseEntity.ok(recetaService.listarTodas());
    }

    @GetMapping("/{id}")
    public ResponseEntity<RecetaResponseDTO> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(recetaService.obtenerPorId(id));
    }

    @GetMapping("/producto/{codigo}")
    public ResponseEntity<RecetaResponseDTO> obtenerPorCodigoProducto(@PathVariable String codigo) {
        return ResponseEntity.ok(recetaService.obtenerPorCodigoProducto(codigo));
    }

    @PostMapping
    public ResponseEntity<RecetaResponseDTO> crear(@Valid @RequestBody RecetaRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(recetaService.crear(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RecetaResponseDTO> actualizar(@PathVariable Long id, @Valid @RequestBody RecetaRequestDTO dto) {
        return ResponseEntity.ok(recetaService.actualizar(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        recetaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
