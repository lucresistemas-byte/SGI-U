package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ConfiguracionDTO;
import com.sgiu_group.sgiu.models.dtos.MarcaNegocioDTO;
import com.sgiu_group.sgiu.services.ConfiguracionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/configuracion")
@RequiredArgsConstructor
public class ConfiguracionController {

    private final ConfiguracionService configuracionService;

    @GetMapping
    public ResponseEntity<ConfiguracionDTO> obtenerConfiguracion() {
        return ResponseEntity.ok(configuracionService.obtenerConfiguracion());
    }

    /** Público (sin token): el login muestra el nombre y el logo del negocio. */
    @GetMapping("/marca")
    public ResponseEntity<MarcaNegocioDTO> obtenerMarca() {
        return ResponseEntity.ok(configuracionService.obtenerMarca());
    }

    @PutMapping
    public ResponseEntity<ConfiguracionDTO> actualizarConfiguracion(@RequestBody ConfiguracionDTO dto) {
        return ResponseEntity.ok(configuracionService.actualizarConfiguracion(dto));
    }
}
