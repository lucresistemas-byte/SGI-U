package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.CategoriaDTO;
import com.sgiu_group.sgiu.models.dtos.EstadoRequestDTO;
import com.sgiu_group.sgiu.services.CategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/categorias")
@RequiredArgsConstructor
public class CategoriaController {

    private final CategoriaService categoriaService;

    @GetMapping
    public ResponseEntity<List<CategoriaDTO>> listarCategorias(
            @RequestParam(defaultValue = "false") boolean incluirInactivas) {
        return ResponseEntity.ok(categoriaService.listarCategorias(incluirInactivas));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CategoriaDTO> actualizarCategoria(@PathVariable Long id,
                                                            @RequestBody @Valid CategoriaDTO dto) {
        return ResponseEntity.ok(categoriaService.actualizarCategoria(id, dto));
    }

    /** Las categorías no se eliminan: se desactivan o reactivan. */
    @PatchMapping("/{id}/estado")
    public ResponseEntity<CategoriaDTO> cambiarEstado(@PathVariable Long id,
                                                      @Valid @RequestBody EstadoRequestDTO dto) {
        return ResponseEntity.ok(categoriaService.cambiarEstado(id, dto.activo()));
    }

    @PostMapping
    public ResponseEntity<CategoriaDTO> crearCategoria(@RequestBody @Valid CategoriaDTO dto) {
        CategoriaDTO creada = categoriaService.crearCategoria(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(creada);
    }
}
