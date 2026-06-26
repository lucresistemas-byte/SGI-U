package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.dashboard.DashboardResponseDTO;
import com.sgiu_group.sgiu.services.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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
            @RequestParam(required = false) String metodoPago,
            @RequestParam(required = false) Long productoId,
            @RequestParam(required = false) String tipoTransaccion) {

        DashboardResponseDTO response = dashboardService.obtenerDashboard(
                fechaDesde, fechaHasta, metodoPago, productoId, tipoTransaccion);
        return ResponseEntity.ok(response);
    }
}
