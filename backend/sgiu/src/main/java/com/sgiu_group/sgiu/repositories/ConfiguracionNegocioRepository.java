package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.ConfiguracionNegocio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ConfiguracionNegocioRepository extends JpaRepository<ConfiguracionNegocio, Long> {

    Optional<ConfiguracionNegocio> findFirstByOrderByIdAsc();
}
