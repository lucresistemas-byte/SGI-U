package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.MovimientoStock;
import com.sgiu_group.sgiu.models.entities.TipoMovimientoStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface MovimientoStockRepository extends JpaRepository<MovimientoStock, Long> {

    /** Movimientos de un artículo en un rango, opcionalmente de un tipo. Más recientes primero. */
    @Query("""
           SELECT m FROM MovimientoStock m JOIN FETCH m.articulo a
           WHERE a.codigo = :codigo AND m.fecha >= :desde AND m.fecha < :hasta
             AND (:tipo IS NULL OR m.tipo = :tipo)
           ORDER BY m.fecha DESC, m.id DESC
           """)
    List<MovimientoStock> buscar(@Param("codigo") String codigo, @Param("desde") LocalDateTime desde,
                                 @Param("hasta") LocalDateTime hasta, @Param("tipo") TipoMovimientoStock tipo);

    List<MovimientoStock> findByArticulo_CodigoOrderByIdAsc(String codigo);
}
