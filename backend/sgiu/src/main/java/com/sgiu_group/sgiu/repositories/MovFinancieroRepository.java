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
           "WHERE m.fechaHora >= :fechaDesde AND m.fechaHora < :fechaHasta AND m.tipo = :tipo")
    BigDecimal sumByTipoEnRango(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("tipo") TipoMovimiento tipo);

    /** Como sumByTipoEnRango, solo de un método de pago (null = todos). */
    @Query("SELECT SUM(m.monto) FROM MovFinanciero m " +
           "WHERE m.fechaHora >= :fechaDesde AND m.fechaHora < :fechaHasta AND m.tipo = :tipo " +
           "AND (:metodoPagoId IS NULL OR m.metodoPago.id = :metodoPagoId)")
    BigDecimal sumByTipoYMetodoEnRango(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("tipo") TipoMovimiento tipo,
            @Param("metodoPagoId") Long metodoPagoId);

    /** Ingresos cargados a mano (sin venta del POS) del rango; método null = todos. */
    @Query("SELECT SUM(m.monto) FROM MovFinanciero m " +
           "WHERE m.fechaHora >= :fechaDesde AND m.fechaHora < :fechaHasta " +
           "AND m.tipo = com.sgiu_group.sgiu.models.entities.TipoMovimiento.INGRESO AND m.pago IS NULL " +
           "AND (:metodoPagoId IS NULL OR m.metodoPago.id = :metodoPagoId)")
    BigDecimal sumIngresosSinVenta(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);

    /** Egresos del rango por categoría: [categoria, monto]; método null = todos. */
    @Query("SELECT m.categoria, SUM(m.monto) FROM MovFinanciero m " +
           "WHERE m.fechaHora >= :fechaDesde AND m.fechaHora < :fechaHasta " +
           "AND m.tipo = com.sgiu_group.sgiu.models.entities.TipoMovimiento.EGRESO " +
           "AND (:metodoPagoId IS NULL OR m.metodoPago.id = :metodoPagoId) " +
           "GROUP BY m.categoria")
    List<Object[]> sumEgresosPorCategoria(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);

    @Query("SELECT FUNCTION('DATE', m.fechaHora), " +
           "SUM(CASE WHEN m.tipo = 'INGRESO' THEN m.monto ELSE 0 END), " +
           "SUM(CASE WHEN m.tipo = 'EGRESO' THEN m.monto ELSE 0 END) " +
           "FROM MovFinanciero m " +
           "WHERE m.fechaHora >= :fechaDesde AND m.fechaHora < :fechaHasta " +
           "AND (:metodoPagoId IS NULL OR m.metodoPago.id = :metodoPagoId) " +
           "GROUP BY FUNCTION('DATE', m.fechaHora) " +
           "ORDER BY FUNCTION('DATE', m.fechaHora)")
    List<Object[]> findIngresosEgresosPorDia(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);

    @Query("SELECT FUNCTION('DATE', m.fechaHora), " +
           "SUM(CASE WHEN m.tipo = 'INGRESO' THEN m.monto ELSE -m.monto END) " +
           "FROM MovFinanciero m " +
           "WHERE m.fechaHora >= :fechaDesde AND m.fechaHora < :fechaHasta " +
           "AND (:metodoPagoId IS NULL OR m.metodoPago.id = :metodoPagoId) " +
           "GROUP BY FUNCTION('DATE', m.fechaHora) " +
           "ORDER BY FUNCTION('DATE', m.fechaHora)")
    List<Object[]> findSaldoNetoAcumuladoPorDia(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);
}
