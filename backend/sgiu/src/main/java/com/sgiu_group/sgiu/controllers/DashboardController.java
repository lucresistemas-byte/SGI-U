package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.services.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.sgiu_group.sgiu.exceptions.FiltroInvalidoException;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/dashboard")
@PreAuthorize("isAuthenticated()")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping
    public ResponseEntity<DashboardResponseDTO> getDashboard(
            @RequestParam LocalDate fechaDesde,
            @RequestParam LocalDate fechaHasta,
            @RequestParam(required = false) Long metodoPagoId,
            @RequestParam(required = false) Long productoId,
            @RequestParam(required = false) String tipoTransaccion,
            @RequestParam(required = false) String tipoProducto) {

        DashboardResponseDTO response = dashboardService.obtenerDashboard(
                fechaDesde, fechaHasta, metodoPagoId, productoId, tipoTransaccion, tipoDe(tipoProducto));
        return ResponseEntity.ok(response);
    }

    /** ELABORADO, REVENTA, REVENTA_MATERIA_PRIMA o PAQUETE; vacío = todos. */
    private static TipoArticulo tipoDe(String tipo) {
        if (tipo == null || tipo.isBlank()) return null;
        try {
            return TipoArticulo.valueOf(tipo.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new FiltroInvalidoException("El tipo de producto especificado no existe.");
        }
    }
}
