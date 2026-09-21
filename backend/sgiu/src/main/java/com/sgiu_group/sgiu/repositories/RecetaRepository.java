package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.Receta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RecetaRepository extends JpaRepository<Receta, Long> {
    Optional<Receta> findByProducto_IdAndActivoTrue(Long productoId);
    Optional<Receta> findByProducto_CodigoAndActivoTrue(String codigo);
    Optional<Receta> findByProducto(EspProducto producto);
    List<Receta> findByActivoTrue();

    @Query("SELECT DISTINCT r FROM Receta r JOIN r.detalles d WHERE d.materiaPrima.id = :materiaPrimaId AND r.activo = true")
    List<Receta> findRecetasByMateriaPrimaId(@Param("materiaPrimaId") Long materiaPrimaId);
}
