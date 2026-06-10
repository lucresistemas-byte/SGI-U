package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.MovFinanciero;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface MovFinancieroRepository extends JpaRepository<MovFinanciero, Long> {

    List<MovFinanciero> findAllByOrderByFechaHoraDesc();

    @Query("SELECT m FROM MovFinanciero m WHERE m.fechaHora >= :inicio AND m.fechaHora < :fin ORDER BY m.fechaHora DESC")
    List<MovFinanciero> findEnRango(@Param("inicio") LocalDateTime inicio, @Param("fin") LocalDateTime fin);
}
