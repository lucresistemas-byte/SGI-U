package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MovFinancieroRepository extends JpaRepository<MovFinanciero, Long> {

    List<MovFinanciero> findAllByOrderByFechaHoraDesc();
}
