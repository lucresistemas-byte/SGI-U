package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.HistorialPrecioDTO;
import com.sgiu_group.sgiu.services.HistorialPrecioService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** Historial de precios (pestaña de Productos): filtros por fecha y producto. */
@RestController
@RequestMapping("/api/precios/historial")
@RequiredArgsConstructor
public class HistorialPrecioController {

    private final HistorialPrecioService historialService;

    @GetMapping
    public ResponseEntity<List<HistorialPrecioDTO>> buscar(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestParam(required = false) String codigo) {
        return ResponseEntity.ok(historialService.buscar(desde, hasta, codigo));
    }
}
