package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.EstadoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MetodoPagoDTO;
import com.sgiu_group.sgiu.models.dtos.MetodoPagoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.OrdenMetodosPagoDTO;
import com.sgiu_group.sgiu.services.MetodoPagoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/metodos-pago")
@RequiredArgsConstructor
public class MetodoPagoController {

    private final MetodoPagoService service;

    @GetMapping
    public ResponseEntity<List<MetodoPagoDTO>> listar(
            @RequestParam(defaultValue = "false") boolean incluirInactivos) {
        return ResponseEntity.ok(service.listar(incluirInactivos));
    }

    @PostMapping
    public ResponseEntity<MetodoPagoDTO> crear(@Valid @RequestBody MetodoPagoRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.crear(dto.nombre()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<MetodoPagoDTO> renombrar(@PathVariable Long id,
                                                   @Valid @RequestBody MetodoPagoRequestDTO dto) {
        return ResponseEntity.ok(service.renombrar(id, dto.nombre()));
    }

    /** No se eliminan: se desactivan o reactivan. */
    @PatchMapping("/{id}/estado")
    public ResponseEntity<MetodoPagoDTO> cambiarEstado(@PathVariable Long id,
                                                       @Valid @RequestBody EstadoRequestDTO dto) {
        return ResponseEntity.ok(service.cambiarEstado(id, dto.activo()));
    }

    @PutMapping("/orden")
    public ResponseEntity<List<MetodoPagoDTO>> reordenar(@Valid @RequestBody OrdenMetodosPagoDTO dto) {
        return ResponseEntity.ok(service.reordenar(dto.ids()));
    }
}
