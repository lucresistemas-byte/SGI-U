package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EspProductoRepository extends JpaRepository<EspProducto, Long> {

    @Query("""
           SELECT new com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO(
               p.codigo, 
               'Producto ' || p.codigo, 
               p.precioUnitario, 
               COALESCE(SUM(s.cantidad), 0L)
           )
           FROM EspProducto p
           LEFT JOIN ArticuloStock s ON s.espProducto = p
           GROUP BY p.codigo, p.precioUnitario
           """)
    List<ProductoCatalogoDTO> obtenerCatalogo();
}
