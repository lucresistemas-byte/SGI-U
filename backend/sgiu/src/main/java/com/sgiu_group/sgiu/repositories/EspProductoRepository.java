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

    // NUEVO: Le enseñamos a Spring a buscar por el código de texto
    Optional<EspProducto> findByCodigo(String codigo);

<<<<<<< HEAD
=======
    boolean existsByCodigo(String codigo);

>>>>>>> b8680ed (feat: agregar login)
    @Query("""
           SELECT new com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO(
               p.codigo, 
               p.nombre, 
               p.precioUnitario, 
               COALESCE(SUM(s.cantidad), 0L),
               p.activo
           )
           FROM EspProducto p
           LEFT JOIN ArticuloStock s ON s.espProducto = p
           GROUP BY p.codigo, p.nombre, p.precioUnitario, p.activo
           """)
    List<ProductoCatalogoDTO> obtenerCatalogo();
<<<<<<< HEAD
<<<<<<< HEAD
    boolean existsByCodigo(String codigo);
    java.util.Optional<com.sgiu_group.sgiu.models.entities.EspProducto> findByCodigo(String codigo);
=======
    // (Nota: le saqué el WHERE p.activo = true porque ahora Flutter se encarga de mostrar inactivos)
>>>>>>> origin/iteracion-2-frontend
=======

    // (Nota: le saqué el WHERE p.activo = true porque ahora Flutter se encarga de mostrar inactivos)
>>>>>>> b8680ed (feat: agregar login)
}