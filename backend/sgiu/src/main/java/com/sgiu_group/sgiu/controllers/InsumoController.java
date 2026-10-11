package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.AjusteStockInsumoDTO;
import com.sgiu_group.sgiu.models.dtos.EstadoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.InsumoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.InsumoResponseDTO;
import com.sgiu_group.sgiu.services.MateriaPrimaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/insumos")
@RequiredArgsConstructor
public class InsumoController {

    private final MateriaPrimaService materiaPrimaService;

    @GetMapping
    public ResponseEntity<List<InsumoResponseDTO>> listarTodos(
            @RequestParam(defaultValue = "false") boolean incluirInactivos) {
        return ResponseEntity.ok(materiaPrimaService.listarTodos(incluirInactivos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<InsumoResponseDTO> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(materiaPrimaService.obtenerPorId(id));
    }

    @PostMapping
    public ResponseEntity<InsumoResponseDTO> crear(@Valid @RequestBody InsumoRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(materiaPrimaService.crear(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<InsumoResponseDTO> actualizar(@PathVariable Long id, @Valid @RequestBody InsumoRequestDTO dto) {
        return ResponseEntity.ok(materiaPrimaService.actualizar(id, dto));
    }

    /** Los insumos no se eliminan: se activan o desactivan. */
    @PatchMapping("/{id}/estado")
    public ResponseEntity<InsumoResponseDTO> cambiarEstado(@PathVariable Long id,
                                                           @Valid @RequestBody EstadoRequestDTO dto) {
        return ResponseEntity.ok(materiaPrimaService.cambiarEstado(id, dto.activo()));
    }

    @PostMapping("/{id}/ajuste-stock")
    public ResponseEntity<InsumoResponseDTO> ajustarStock(@PathVariable Long id, @Valid @RequestBody AjusteStockInsumoDTO dto) {
        return ResponseEntity.ok(materiaPrimaService.ajustarStock(id, dto));
    }
}
