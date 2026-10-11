package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoResponseDTO;
import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import com.sgiu_group.sgiu.repositories.LineaVentaRepository;
import com.sgiu_group.sgiu.repositories.MovFinancieroRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

@Service
public class MovimientoService {

    private final MovFinancieroRepository repository;
    private final LineaVentaRepository lineaVentaRepository;

    public MovimientoService(MovFinancieroRepository repository,
                             LineaVentaRepository lineaVentaRepository) {
        this.repository = repository;
        this.lineaVentaRepository = lineaVentaRepository;
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
        return aDTOs(repository.findAllByOrderByFechaHoraDesc());
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

        List<MovFinanciero> movimientosEntidad = repository.findEnRango(desde, hasta);
        List<MovimientoResponseDTO> movimientosDTO = aDTOs(movimientosEntidad);

        BigDecimal costoTotal = movimientosDTO.stream()
                .filter(m -> "INGRESO".equalsIgnoreCase(m.tipo()))
                .map(m -> m.costo() != null ? m.costo() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal gananciaReal = ingresos.subtract(costoTotal).subtract(egresos);

        return new BalanceResponseDTO(
                ingresos,
                egresos,
                ingresos.subtract(egresos),
                costoTotal,
                gananciaReal,
                movimientosDTO
        );
    }

    /** Arma los DTO con el costo de cada venta en una sola consulta agregada. */
    private List<MovimientoResponseDTO> aDTOs(List<MovFinanciero> movimientos) {
        List<Long> ventaIds = movimientos.stream()
                .map(MovimientoService::ventaId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();

        Map<Long, BigDecimal> costoPorVenta = new HashMap<>();
        if (!ventaIds.isEmpty()) {
            for (Object[] fila : lineaVentaRepository.sumarCostoPorVenta(ventaIds)) {
                costoPorVenta.put((Long) fila[0], new BigDecimal(fila[1].toString()));
            }
        }

        return movimientos.stream()
                .map(m -> MovimientoResponseDTO.fromEntity(m, costoPorVenta.get(ventaId(m))))
                .toList();
    }

    private static Long ventaId(MovFinanciero mov) {
        if (mov.getPago() == null || mov.getPago().getVenta() == null) {
            return null;
        }
        return mov.getPago().getVenta().getId();
    }
}
