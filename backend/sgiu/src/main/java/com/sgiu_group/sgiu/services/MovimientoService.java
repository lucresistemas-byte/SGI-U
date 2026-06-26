package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoResponseDTO;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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

    @Transactional(readOnly = true)
    public BalanceResponseDTO calcularBalance(LocalDate inicio, LocalDate fin) {
        if (inicio.isAfter(fin)) {
            throw new IllegalArgumentException("La fecha de inicio no puede ser posterior a la fecha de fin.");
        }

        LocalDateTime desde = inicio.atStartOfDay();
        LocalDateTime hasta = fin.plusDays(1).atStartOfDay();

        BigDecimal ingresos = Optional.ofNullable(
                repository.sumByTipoEnRango(desde, hasta, TipoMovimiento.INGRESO))
                .orElse(BigDecimal.ZERO);

        BigDecimal egresos = Optional.ofNullable(
                repository.sumByTipoEnRango(desde, hasta, TipoMovimiento.EGRESO))
                .orElse(BigDecimal.ZERO);

        return new BalanceResponseDTO(ingresos, egresos, ingresos.subtract(egresos), List.of());
    }
}
