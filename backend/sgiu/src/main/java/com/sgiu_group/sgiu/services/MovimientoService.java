package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.BalanceResponseDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MovimientoResponseDTO;
import com.sgiu_group.sgiu.models.entities.CategoriaMovimiento;
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
    private final MetodoPagoService metodoPagoService;

    public MovimientoService(MovFinancieroRepository repository,
                             LineaVentaRepository lineaVentaRepository,
                             MetodoPagoService metodoPagoService) {
        this.repository = repository;
        this.lineaVentaRepository = lineaVentaRepository;
        this.metodoPagoService = metodoPagoService;
    }

    @Transactional
    public MovimientoResponseDTO crearMovimiento(MovimientoRequestDTO dto) {
        TipoMovimiento tipo;
        try {
            tipo = TipoMovimiento.valueOf(dto.tipo());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("El tipo de movimiento debe ser INGRESO o EGRESO.");
        }

        String categoria = validarCategoria(tipo, dto.categoria());
        LocalDateTime fechaHora = dto.fechaHora() != null ? dto.fechaHora() : LocalDateTime.now();
        // Se compara por día: un reloj de la caja unos minutos adelantado no
        // hace fallar un alta de hoy.
        if (fechaHora.toLocalDate().isAfter(LocalDate.now())) {
            throw new IllegalArgumentException("La fecha del movimiento no puede ser posterior a hoy.");
        }

        MovFinanciero mov = new MovFinanciero(
                tipo,
                dto.monto(),
                metodoPagoService.paraCobrar(dto.metodoPagoId()),
                categoria,
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

    /** Normaliza la categoría a su código y verifica que corresponda al tipo. */
    private static String validarCategoria(TipoMovimiento tipo, String categoria) {
        if (categoria == null || categoria.isBlank()) {
            throw new IllegalArgumentException("La categoría es obligatoria.");
        }
        String codigo = categoria.trim().toUpperCase();
        List<CategoriaMovimiento> validas = CategoriaMovimiento.para(tipo);
        if (validas.stream().noneMatch(c -> c.name().equals(codigo))) {
            String opciones = String.join(", ", validas.stream().map(Enum::name).toList());
            throw new IllegalArgumentException("La categoría " + codigo + " no corresponde a un "
                    + tipo.name() + ". Categorías válidas: " + opciones + ".");
        }
        return codigo;
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

        Map<MovFinanciero, BigDecimal> costoPorMovimiento = repartirCosto(movimientos, costoPorVenta);
        return movimientos.stream()
                .map(m -> MovimientoResponseDTO.fromEntity(m, costoPorMovimiento.get(m)))
                .toList();
    }

    /**
     * Una venta con pago mixto tiene un movimiento por método: su costo se
     * reparte en proporción a lo cobrado con cada uno (el último se lleva el
     * resto del redondeo), para no contarlo dos veces en el balance.
     */
    private static Map<MovFinanciero, BigDecimal> repartirCosto(List<MovFinanciero> movimientos,
                                                                Map<Long, BigDecimal> costoPorVenta) {
        Map<Long, List<MovFinanciero>> porVenta = new java.util.LinkedHashMap<>();
        for (MovFinanciero m : movimientos) {
            Long venta = ventaId(m);
            if (venta != null && costoPorVenta.containsKey(venta)) {
                porVenta.computeIfAbsent(venta, k -> new java.util.ArrayList<>()).add(m);
            }
        }
        Map<MovFinanciero, BigDecimal> resultado = new java.util.IdentityHashMap<>();
        porVenta.forEach((venta, movs) -> {
            BigDecimal costo = costoPorVenta.get(venta);
            BigDecimal cobrado = movs.stream().map(MovFinanciero::getMonto).reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal asignado = BigDecimal.ZERO;
            for (int i = 0; i < movs.size(); i++) {
                MovFinanciero m = movs.get(i);
                BigDecimal parte = i == movs.size() - 1 || cobrado.signum() == 0
                        ? costo.subtract(asignado)
                        : costo.multiply(m.getMonto()).divide(cobrado, 2, java.math.RoundingMode.HALF_UP);
                asignado = asignado.add(parte);
                resultado.put(m, parte);
            }
        });
        return resultado;
    }

    private static Long ventaId(MovFinanciero mov) {
        if (mov.getPago() == null || mov.getPago().getVenta() == null) {
            return null;
        }
        return mov.getPago().getVenta().getId();
    }
}
