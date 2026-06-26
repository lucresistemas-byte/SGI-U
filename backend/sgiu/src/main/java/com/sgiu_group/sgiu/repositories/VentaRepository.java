package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.Venta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface VentaRepository extends JpaRepository<Venta, Long> {

    @Query("SELECT COUNT(v) FROM Venta v WHERE v.fechaHora BETWEEN :fechaDesde AND :fechaHasta")
    Long countVentasEnRango(@Param("fechaDesde") LocalDateTime fechaDesde, @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT SUM(v.total) FROM Venta v WHERE v.fechaHora BETWEEN :fechaDesde AND :fechaHasta")
    BigDecimal sumTotalVentasEnRango(@Param("fechaDesde") LocalDateTime fechaDesde, @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT FUNCTION('DATE', v.fechaHora), COUNT(v), SUM(v.total) FROM Venta v WHERE v.fechaHora BETWEEN :fechaDesde AND :fechaHasta GROUP BY FUNCTION('DATE', v.fechaHora) ORDER BY FUNCTION('DATE', v.fechaHora)")
    List<Object[]> findVentasAgrupadasPorDia(@Param("fechaDesde") LocalDateTime fechaDesde, @Param("fechaHasta") LocalDateTime fechaHasta);
}
