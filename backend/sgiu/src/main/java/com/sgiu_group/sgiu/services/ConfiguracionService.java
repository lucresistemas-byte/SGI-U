package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ConfiguracionDTO;
import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import com.sgiu_group.sgiu.repositories.ConfiguracionNegocioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ConfiguracionService {

    private final ConfiguracionNegocioRepository configuracionRepository;

    @Transactional
    public ConfiguracionDTO obtenerConfiguracion() {
        ConfiguracionNegocio config = configuracionRepository.findFirstByOrderByIdAsc()
                .orElseGet(() -> {
                    ConfiguracionNegocio nueva = new ConfiguracionNegocio("SGI-U Comercio", "SGIU-SANDRA-001");
                    return configuracionRepository.save(nueva);
                });

        return new ConfiguracionDTO(
                config.getNombre(),
                config.getCodigoCliente(),
                config.getLogo(),
                config.getDireccion(),
                config.getTelefono(),
                config.getDescripcion()
        );
    }

    @Transactional
    public ConfiguracionDTO actualizarConfiguracion(ConfiguracionDTO dto) {
        ConfiguracionNegocio config = configuracionRepository.findFirstByOrderByIdAsc()
                .orElseGet(() -> new ConfiguracionNegocio("SGI-U Comercio", "SGIU-SANDRA-001"));

        if (dto.nombre() != null && !dto.nombre().isBlank()) {
            config.setNombre(dto.nombre().trim());
        }
        if (dto.codigoCliente() != null && !dto.codigoCliente().isBlank()) {
            config.setCodigoCliente(dto.codigoCliente().trim());
        }
        if (dto.direccion() != null) {
            config.setDireccion(dto.direccion());
        }
        if (dto.telefono() != null) {
            config.setTelefono(dto.telefono());
        }
        if (dto.descripcion() != null) {
            config.setDescripcion(dto.descripcion());
        }
        // Preserva el logo anterior si no se envía uno nuevo según spec 6.2
        if (dto.logo() != null && dto.logo().length > 0) {
            config.setLogo(dto.logo());
        }

        ConfiguracionNegocio guardada = configuracionRepository.save(config);

        return new ConfiguracionDTO(
                guardada.getNombre(),
                guardada.getCodigoCliente(),
                guardada.getLogo(),
                guardada.getDireccion(),
                guardada.getTelefono(),
                guardada.getDescripcion()
        );
    }
}
