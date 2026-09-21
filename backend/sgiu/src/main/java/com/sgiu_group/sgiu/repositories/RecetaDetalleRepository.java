package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecetaDetalleRepository extends JpaRepository<RecetaDetalle, Long> {
    List<RecetaDetalle> findByReceta_Id(Long recetaId);
    void deleteByReceta_Id(Long recetaId);
}
