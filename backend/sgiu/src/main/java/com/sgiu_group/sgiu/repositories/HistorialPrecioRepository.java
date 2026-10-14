package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.HistorialPrecio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface HistorialPrecioRepository extends JpaRepository<HistorialPrecio, Long> {

    /** Filtros opcionales: rango de fechas y artículo (por código). Más recientes primero. */
    @Query("""
           SELECT h FROM HistorialPrecio h JOIN FETCH h.articulo a
           WHERE h.fecha >= :desde AND h.fecha < :hasta
             AND (:codigo IS NULL OR a.codigo = :codigo)
           ORDER BY h.fecha DESC, h.id DESC
           """)
    List<HistorialPrecio> buscar(@Param("desde") LocalDateTime desde, @Param("hasta") LocalDateTime hasta,
                                 @Param("codigo") String codigo);

    /** Si el artículo tuvo ese precio de venta desde [desde] (precio congelado en un carrito). */
    @Query("""
           SELECT COUNT(h) > 0 FROM HistorialPrecio h
           WHERE h.articulo.id = :articuloId AND h.precioAnterior = :precio AND h.fecha >= :desde
           """)
    boolean tuvoPrecioDesde(@Param("articuloId") Long articuloId, @Param("precio") BigDecimal precio,
                            @Param("desde") LocalDateTime desde);
}
