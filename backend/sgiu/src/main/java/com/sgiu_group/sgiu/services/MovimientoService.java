package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoResponseDTO;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class MovimientoService {

    private final MovFinancieroRepository repository;

    public MovimientoService(MovFinancieroRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public MovimientoResponseDTO crearMovimiento(MovimientoRequestDTO dto) {
        TipoMovimiento tipo;
        try {
            tipo = TipoMovimiento.valueOf(dto.tipo());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("El tipo de movimiento debe ser INGRESO o EGRESO.");
        }

        LocalDateTime fechaHora = dto.fechaHora() != null ? dto.fechaHora() : LocalDateTime.now();

        MovFinanciero mov = new MovFinanciero(
                tipo,
                dto.monto(),
                dto.metodoPago(),
                dto.categoria(),
                dto.descripcion(),
                fechaHora,
                null
        );

        mov = repository.save(mov);
        return MovimientoResponseDTO.fromEntity(mov);
    }

    @Transactional(readOnly = true)
    public List<MovimientoResponseDTO> listarMovimientos() {
        return repository.findAllByOrderByFechaHoraDesc()
                .stream()
                .map(MovimientoResponseDTO::fromEntity)
                .toList();
    }
}
