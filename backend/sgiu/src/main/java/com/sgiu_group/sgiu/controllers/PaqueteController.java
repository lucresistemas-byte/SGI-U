package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.EstadoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.PaqueteRequestDTO;
import com.sgiu_group.sgiu.models.dtos.PaqueteResponseDTO;
import com.sgiu_group.sgiu.services.PaqueteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Paquetes: armado con insumos + monto fijo (sección Recetas y paquetes). */
@RestController
@RequestMapping("/api/paquetes")
@RequiredArgsConstructor
public class PaqueteController {

    private final PaqueteService paqueteService;

    @GetMapping
    public ResponseEntity<List<PaqueteResponseDTO>> listar() {
        return ResponseEntity.ok(paqueteService.listar());
    }

    @GetMapping("/{id}")
    public ResponseEntity<PaqueteResponseDTO> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(paqueteService.obtener(id));
    }

    @PostMapping
    public ResponseEntity<PaqueteResponseDTO> crear(@Valid @RequestBody PaqueteRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(paqueteService.crear(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<PaqueteResponseDTO> actualizar(@PathVariable Long id,
                                                         @Valid @RequestBody PaqueteRequestDTO dto) {
        return ResponseEntity.ok(paqueteService.actualizar(id, dto));
    }

    /** No se eliminan: se activan o desactivan. */
    @PatchMapping("/{id}/estado")
    public ResponseEntity<PaqueteResponseDTO> cambiarEstado(@PathVariable Long id,
                                                            @Valid @RequestBody EstadoRequestDTO dto) {
        return ResponseEntity.ok(paqueteService.cambiarEstado(id, dto.activo()));
    }
}
