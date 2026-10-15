package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.AjusteStockMateriaPrimaDTO;
import com.sgiu_group.sgiu.models.dtos.EstadoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MateriaPrimaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MateriaPrimaResponseDTO;
import com.sgiu_group.sgiu.services.MateriaPrimaService;
import com.sgiu_group.sgiu.services.ReintentoStock;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Sección Materia Prima: materias primas, insumos y reventa + materia prima del catálogo. */
@RestController
@RequestMapping("/api/materias-primas")
@RequiredArgsConstructor
public class MateriaPrimaController {

    private final MateriaPrimaService materiaPrimaService;
    private final ReintentoStock reintento;

    @GetMapping
    public ResponseEntity<List<MateriaPrimaResponseDTO>> listarTodos(
            @RequestParam(defaultValue = "false") boolean incluirInactivos) {
        return ResponseEntity.ok(materiaPrimaService.listarTodos(incluirInactivos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MateriaPrimaResponseDTO> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(materiaPrimaService.obtenerPorId(id));
    }

    @PostMapping
    public ResponseEntity<MateriaPrimaResponseDTO> crear(@Valid @RequestBody MateriaPrimaRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(materiaPrimaService.crear(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<MateriaPrimaResponseDTO> actualizar(@PathVariable Long id,
                                                              @Valid @RequestBody MateriaPrimaRequestDTO dto) {
        return ResponseEntity.ok(materiaPrimaService.actualizar(id, dto));
    }

    /** No se eliminan: se activan o desactivan. */
    @PatchMapping("/{id}/estado")
    public ResponseEntity<MateriaPrimaResponseDTO> cambiarEstado(@PathVariable Long id,
                                                                 @Valid @RequestBody EstadoRequestDTO dto) {
        return ResponseEntity.ok(materiaPrimaService.cambiarEstado(id, dto.activo()));
    }

    @PostMapping("/{id}/ajuste-stock")
    public ResponseEntity<MateriaPrimaResponseDTO> ajustarStock(@PathVariable Long id,
                                                                @Valid @RequestBody AjusteStockMateriaPrimaDTO dto) {
        return ResponseEntity.ok(reintento.ejecutar(() -> materiaPrimaService.ajustarStock(id, dto)));
    }
}
