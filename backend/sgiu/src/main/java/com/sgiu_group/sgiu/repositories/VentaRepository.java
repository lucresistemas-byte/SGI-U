package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.Venta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface VentaRepository extends JpaRepository<Venta, Long> {

    /** A2: idempotencia de venta; si el token ya se usó, se devuelve la venta existente. */
    Optional<Venta> findByTokenIdempotencia(String tokenIdempotencia);

    @Query("SELECT COUNT(v) FROM Venta v WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta")
    Long countVentasEnRango(@Param("fechaDesde") LocalDateTime fechaDesde, @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT SUM(v.total) FROM Venta v WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta")
    BigDecimal sumTotalVentasEnRango(@Param("fechaDesde") LocalDateTime fechaDesde, @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT FUNCTION('DATE', v.fechaHora), COUNT(v), SUM(v.total) FROM Venta v WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta GROUP BY FUNCTION('DATE', v.fechaHora) ORDER BY FUNCTION('DATE', v.fechaHora)")
    List<Object[]> findVentasAgrupadasPorDia(@Param("fechaDesde") LocalDateTime fechaDesde, @Param("fechaHasta") LocalDateTime fechaHasta);
}
