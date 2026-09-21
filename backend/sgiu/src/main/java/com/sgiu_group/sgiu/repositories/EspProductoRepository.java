package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EspProductoRepository extends JpaRepository<EspProducto, Long> {

    Optional<EspProducto> findByCodigo(String codigo);

    boolean existsByCodigo(String codigo);

    @Query("""
           SELECT new com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO(
               p.codigo,
               p.nombre,
               p.precioUnitario,
               p.precioCosto,
               p.porcentajeGanancia,
               p.unidadMedida,
               c.nombre,
               COALESCE(SUM(s.cantidad), 0L),
               COALESCE(s.stockMinimo, 0),
               p.activo
           )
           FROM EspProducto p
           LEFT JOIN p.categoria c
           LEFT JOIN ArticuloStock s ON s.espProducto = p
           GROUP BY p.codigo, p.nombre, p.precioUnitario, p.precioCosto, p.porcentajeGanancia, p.unidadMedida, c.nombre, p.activo, s.stockMinimo
           """)
    List<ProductoCatalogoDTO> obtenerCatalogo();

    @Query("""
           SELECT new com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO(
               p.codigo,
               p.nombre,
               p.precioUnitario,
               p.precioCosto,
               p.porcentajeGanancia,
               p.unidadMedida,
               c.nombre,
               COALESCE(SUM(s.cantidad), 0L),
               COALESCE(s.stockMinimo, 0),
               p.activo
           )
           FROM EspProducto p
           LEFT JOIN p.categoria c
           LEFT JOIN ArticuloStock s ON s.espProducto = p
           WHERE (:categoria IS NULL OR LOWER(c.nombre) = LOWER(:categoria))
           GROUP BY p.codigo, p.nombre, p.precioUnitario, p.precioCosto, p.porcentajeGanancia, p.unidadMedida, c.nombre, p.activo, s.stockMinimo
           """)
    List<ProductoCatalogoDTO> obtenerCatalogoPorCategoria(@Param("categoria") String categoria);
}