package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.LineaVenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface LineaVentaRepository extends JpaRepository<LineaVenta, Long> {

    @Query("SELECT lv.producto.id, p.nombre, SUM(lv.cantidad), SUM(lv.subtotal) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p " +
           "WHERE v.fechaHora BETWEEN :fechaDesde AND :fechaHasta " +
           "GROUP BY lv.producto.id, p.nombre " +
           "ORDER BY SUM(lv.cantidad) DESC")
    List<Object[]> findTopProductosVendidos(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT c.id, c.nombre, SUM(lv.cantidad), SUM(lv.subtotal) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p JOIN p.categoria c " +
           "WHERE v.fechaHora BETWEEN :fechaDesde AND :fechaHasta " +
           "GROUP BY c.id, c.nombre " +
           "ORDER BY SUM(lv.subtotal) DESC")
    List<Object[]> findTopCategoriasVendidas(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT lv.producto.id, p.nombre, SUM(lv.cantidad), SUM(lv.subtotal) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p LEFT JOIN p.categoria c " +
           "WHERE v.fechaHora BETWEEN :fechaDesde AND :fechaHasta " +
           "AND (:categoriaId IS NULL OR c.id = :categoriaId) " +
           "GROUP BY lv.producto.id, p.nombre " +
           "ORDER BY SUM(lv.cantidad) DESC")
    List<Object[]> findTopProductosVendidosPorCategoria(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("categoriaId") Long categoriaId);
}
