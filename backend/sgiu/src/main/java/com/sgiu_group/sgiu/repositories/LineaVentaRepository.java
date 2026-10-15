package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.LineaVenta;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

public interface LineaVentaRepository extends JpaRepository<LineaVenta, Long> {

    @Query("SELECT lv.producto.id, p.nombre, SUM(lv.cantidad), SUM(lv.subtotal) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p " +
           "WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta " +
           "GROUP BY lv.producto.id, p.nombre " +
           "ORDER BY SUM(lv.cantidad) DESC")
    List<Object[]> findTopProductosVendidos(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    /**
     * Los más vendidos (por unidades; ante empate, por lo vendido en pesos),
     * con [productoId, nombre, unidades, ventas, costo congelado]. Con un
     * tipo, solo los productos de ese tipo.
     */
    @Query("SELECT p.id, p.nombre, SUM(lv.cantidad), SUM(lv.subtotal), " +
           "SUM(COALESCE(lv.costoUnitario, 0) * lv.cantidad) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p " +
           "WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta " +
           "AND (:tipo IS NULL OR p.tipo = :tipo) " +
           "GROUP BY p.id, p.nombre " +
           "ORDER BY SUM(lv.cantidad) DESC, SUM(lv.subtotal) DESC")
    List<Object[]> findTopProductosConCosto(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("tipo") com.sgiu_group.sgiu.models.entities.TipoArticulo tipo,
            Pageable pageable);

    /**
     * Por venta del rango con productos del tipo (esp_productos.tipo): [ventaId,
     * total de la venta, subtotal de esas líneas, su costo congelado].
     */
    @Query("SELECT v.id, v.total, SUM(lv.subtotal), SUM(COALESCE(lv.costoUnitario, 0) * lv.cantidad) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p " +
           "WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta " +
           "AND p.tipo = :tipo " +
           "GROUP BY v.id, v.total")
    List<Object[]> findVentasDeTipo(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("tipo") com.sgiu_group.sgiu.models.entities.TipoArticulo tipo);

    @Query("SELECT c.id, c.nombre, SUM(lv.cantidad), SUM(lv.subtotal) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p JOIN p.categoria c " +
           "WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta " +
           "GROUP BY c.id, c.nombre " +
           "ORDER BY SUM(lv.subtotal) DESC")
    List<Object[]> findTopCategoriasVendidas(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    @Query("SELECT lv.producto.id, p.nombre, SUM(lv.cantidad), SUM(lv.subtotal) " +
           "FROM LineaVenta lv JOIN lv.venta v JOIN lv.producto p LEFT JOIN p.categoria c " +
           "WHERE v.fechaHora >= :fechaDesde AND v.fechaHora < :fechaHasta " +
           "AND (:categoriaId IS NULL OR c.id = :categoriaId) " +
           "GROUP BY lv.producto.id, p.nombre " +
           "ORDER BY SUM(lv.cantidad) DESC")
    List<Object[]> findTopProductosVendidosPorCategoria(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            @Param("categoriaId") Long categoriaId);

    /** Costo congelado (costo_unitario × cantidad) de las ventas del rango. */
    @Query("SELECT SUM(COALESCE(lv.costoUnitario, 0) * lv.cantidad) FROM LineaVenta lv " +
           "WHERE lv.venta.fechaHora >= :fechaDesde AND lv.venta.fechaHora < :fechaHasta")
    java.math.BigDecimal sumCostoEnRango(
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta);

    /**
     * Costo congelado (costo_unitario × cantidad) de cada venta, sin cargar las
     * líneas ni sus productos. Devuelve filas [ventaId, costo].
     */
    @Query("SELECT lv.venta.id, SUM(COALESCE(lv.costoUnitario, 0) * lv.cantidad) " +
           "FROM LineaVenta lv WHERE lv.venta.id IN :ventaIds GROUP BY lv.venta.id")
    List<Object[]> sumarCostoPorVenta(@Param("ventaIds") Collection<Long> ventaIds);
}
