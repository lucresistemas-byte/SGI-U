package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import com.sgiu_group.sgiu.models.entities.TipoMovimiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface MovFinancieroRepository extends JpaRepository<MovFinanciero, Long> {

    List<MovFinanciero> findAllByOrderByFechaHoraDesc();

    @Query("SELECT m FROM MovFinanciero m WHERE m.fechaHora >= :inicio AND m.fechaHora < :fin ORDER BY m.fechaHora DESC")
    List<MovFinanciero> findEnRango(@Param("inicio") LocalDateTime inicio, @Param("fin") LocalDateTime fin);

    @Query("SELECT SUM(m.monto) FROM MovFinanciero m " +
           "WHERE m.fechaHora BETWEEN :fechaDesde AND :fechaHasta AND m.tipo = :tipo")
    BigDecimal sumByTipoEnRango(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("tipo") TipoMovimiento tipo);

    @Query("SELECT FUNCTION('DATE', m.fechaHora), " +
           "SUM(CASE WHEN m.tipo = 'INGRESO' THEN m.monto ELSE 0 END), " +
           "SUM(CASE WHEN m.tipo = 'EGRESO' THEN m.monto ELSE 0 END) " +
           "FROM MovFinanciero m " +
           "WHERE m.fechaHora BETWEEN :fechaDesde AND :fechaHasta " +
           "GROUP BY FUNCTION('DATE', m.fechaHora) " +
           "ORDER BY FUNCTION('DATE', m.fechaHora)")
    List<Object[]> findIngresosEgresosPorDia(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT FUNCTION('DATE', m.fechaHora), " +
           "SUM(CASE WHEN m.tipo = 'INGRESO' THEN m.monto ELSE -m.monto END) " +
           "FROM MovFinanciero m " +
           "WHERE m.fechaHora BETWEEN :fechaDesde AND :fechaHasta " +
           "GROUP BY FUNCTION('DATE', m.fechaHora) " +
           "ORDER BY FUNCTION('DATE', m.fechaHora)")
    List<Object[]> findSaldoNetoAcumuladoPorDia(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);
}
