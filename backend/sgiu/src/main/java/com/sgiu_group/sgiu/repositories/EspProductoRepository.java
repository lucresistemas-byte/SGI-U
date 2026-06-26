package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EspProductoRepository extends JpaRepository<EspProducto, Long> {

    Optional<EspProducto> findByCodigo(String codigo);

    boolean existsByCodigo(String codigo);

    // Nota: se quitó el WHERE p.activo = true porque ahora Flutter se encarga de mostrar inactivos
    @Query("""
           SELECT new com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO(
               p.codigo,
               p.nombre,
               p.precioUnitario,
               COALESCE(SUM(s.cantidad), 0L),
               COALESCE(s.stockMinimo, 0),
               p.activo
           )
           FROM EspProducto p
           LEFT JOIN ArticuloStock s ON s.espProducto = p
           GROUP BY p.codigo, p.nombre, p.precioUnitario, p.activo, s.stockMinimo
           """)
    List<ProductoCatalogoDTO> obtenerCatalogo();
}