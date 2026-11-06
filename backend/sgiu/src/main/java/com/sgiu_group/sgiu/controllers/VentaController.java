package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.AnulacionVentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.VentaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.VentaResponseDTO;
import com.sgiu_group.sgiu.models.dtos.VentaResumenDTO;
import com.sgiu_group.sgiu.services.ReintentoStock;
import com.sgiu_group.sgiu.services.VentaService;
import jakarta.validation.Valid; 
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/ventas")
public class VentaController {

    @Autowired
    private VentaService ventaService;

    @Autowired
    private ReintentoStock reintento;

    /**
     * POST /api/ventas: Crear y cobrar una nueva venta en el POS.
     */
    @PostMapping
    public ResponseEntity<VentaResponseDTO> crearVenta(@Valid @RequestBody VentaRequestDTO request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reintento.ejecutar(() -> ventaService.procesarVenta(request)));
    }

    /**
     * GET /api/ventas: Listar ventas por rango de fecha (por defecto: hoy).
     * R-15: Permite al frontend listar ventas para ver el historial y seleccionar cuál anular.
     */
    @GetMapping
    public ResponseEntity<List<VentaResumenDTO>> listarVentas(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta) {
        return ResponseEntity.ok(ventaService.listarVentasPorFecha(desde, hasta));
    }

    /**
     * PUT /api/ventas/{id}/anular: Anulación total de venta con motivo (R-15).
     * Revierte stock, movimientos financieros de caja y marca la venta como anulada.
     */
    @PutMapping("/{id}/anular")
    public ResponseEntity<VentaResumenDTO> anularVenta(
            @PathVariable Long id,
            @Valid @RequestBody AnulacionVentaRequestDTO request,
            Authentication auth) {
        String username = (auth != null) ? auth.getName() : "ADMIN";
        VentaResumenDTO anulada = ventaService.anularVenta(id, request.motivo(), username);
        return ResponseEntity.ok(anulada);
    }
}
