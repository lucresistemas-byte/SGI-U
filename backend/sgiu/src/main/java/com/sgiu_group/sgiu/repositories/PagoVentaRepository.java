package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.PagoVenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface PagoVentaRepository extends JpaRepository<PagoVenta, Long> {

    @Query("SELECT pv.metodo, COUNT(pv.venta), SUM(pv.venta.total) " +
           "FROM PagoVenta pv " +
           "WHERE pv.venta.fechaHora BETWEEN :fechaDesde AND :fechaHasta " +
           "GROUP BY pv.metodo")
    List<Object[]> findVentasAgrupadasPorMetodoPago(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);
}
