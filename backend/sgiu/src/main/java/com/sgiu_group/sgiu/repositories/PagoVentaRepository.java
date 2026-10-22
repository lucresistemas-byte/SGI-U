package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.PagoVenta;
import com.sgiu_group.sgiu.models.entities.Venta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface PagoVentaRepository extends JpaRepository<PagoVenta, Long> {

    List<PagoVenta> findByVenta(Venta venta);

    List<PagoVenta> findByVentaId(Long ventaId);

    /**
     * Por método: nombre, cantidad de ventas que lo usaron y monto cobrado con
     * él (en un pago mixto, cada método suma solo su parte).
     */
    @Query("SELECT pv.metodoPago.nombre, COUNT(DISTINCT pv.venta.id), SUM(pv.monto) " +
           "FROM PagoVenta pv " +
           "WHERE pv.venta.fechaHora >= :fechaDesde AND pv.venta.fechaHora < :fechaHasta " +
           "GROUP BY pv.metodoPago.id, pv.metodoPago.nombre, pv.metodoPago.orden " +
           "ORDER BY pv.metodoPago.orden")
    List<Object[]> findVentasAgrupadasPorMetodoPago(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    /** Ventas con al menos un pago del método. */
    @Query("SELECT COUNT(DISTINCT pv.venta.id) FROM PagoVenta pv " +
           "WHERE pv.venta.fechaHora >= :fechaDesde AND pv.venta.fechaHora < :fechaHasta " +
           "AND pv.metodoPago.id = :metodoPagoId")
    Long countVentasConMetodo(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);

    /** Por venta del rango cobrada con el método: [ventaId, cobrado con él, total de la venta]. */
    @Query("SELECT pv.venta.id, SUM(pv.monto), pv.venta.total FROM PagoVenta pv " +
           "WHERE pv.venta.fechaHora >= :fechaDesde AND pv.venta.fechaHora < :fechaHasta " +
           "AND pv.metodoPago.id = :metodoPagoId " +
           "GROUP BY pv.venta.id, pv.venta.total")
    List<Object[]> findCobrosConMetodo(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);

    /** Lo cobrado con el método en las ventas del rango. */
    @Query("SELECT SUM(pv.monto) FROM PagoVenta pv " +
           "WHERE pv.venta.fechaHora >= :fechaDesde AND pv.venta.fechaHora < :fechaHasta " +
           "AND pv.metodoPago.id = :metodoPagoId")
    BigDecimal sumMontoConMetodo(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("metodoPagoId") Long metodoPagoId);
}
