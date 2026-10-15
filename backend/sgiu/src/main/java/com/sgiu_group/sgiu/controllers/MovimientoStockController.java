package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.MovimientoStockDTO;
import com.sgiu_group.sgiu.services.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/** "Ver historial" de stock de un artículo (Productos y Materia Prima): por fechas y tipo. */
@RestController
@RequestMapping("/api/stock/movimientos")
@RequiredArgsConstructor
public class MovimientoStockController {

    private final StockService stockService;

    @GetMapping("/{codigo}")
    public ResponseEntity<List<MovimientoStockDTO>> historial(
            @PathVariable String codigo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestParam(required = false) String tipo) {
        return ResponseEntity.ok(stockService.historial(codigo, desde, hasta, tipo));
    }
}
