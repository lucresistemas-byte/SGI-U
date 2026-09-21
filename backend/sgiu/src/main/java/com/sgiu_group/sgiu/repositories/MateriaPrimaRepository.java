package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.MateriaPrima;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MateriaPrimaRepository extends JpaRepository<MateriaPrima, Long> {
    Optional<MateriaPrima> findByCodigo(String codigo);
    boolean existsByCodigo(String codigo);
    List<MateriaPrima> findByActivoTrue();
    List<MateriaPrima> findByNombreContainingIgnoreCaseAndActivoTrue(String nombre);
}
