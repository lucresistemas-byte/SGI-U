package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface EspProductoRepository extends JpaRepository<EspProducto, Long> {

    Optional<EspProducto> findByCodigo(String codigo);

    boolean existsByCodigo(String codigo);

    List<EspProducto> findByTipoIn(Collection<TipoArticulo> tipos);

    List<EspProducto> findByTipoInAndActivoTrue(Collection<TipoArticulo> tipos);

    /**
     * Artículos de los tipos dados con su stock (fila [EspProducto,
     * ArticuloStock]; el stock puede ser null), filtrados por categoría si se indica.
     */
    @Query("""
           SELECT p, s
           FROM EspProducto p
           LEFT JOIN p.categoria c
           LEFT JOIN ArticuloStock s ON s.espProducto = p
           WHERE p.tipo IN :tipos
             AND (:categoria IS NULL OR LOWER(c.nombre) = LOWER(:categoria))
           ORDER BY p.codigo
           """)
    List<Object[]> catalogoConStock(@Param("tipos") Collection<TipoArticulo> tipos,
                                    @Param("categoria") String categoria);
}
