package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.MetodoPago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface MetodoPagoRepository extends JpaRepository<MetodoPago, Long> {

    List<MetodoPago> findAllByOrderByOrdenAscIdAsc();

    List<MetodoPago> findByActivoTrueOrderByOrdenAscIdAsc();

    Optional<MetodoPago> findByNombreIgnoreCase(String nombre);

    Optional<MetodoPago> findFirstByFijoTrue();

    @Query("SELECT COALESCE(MAX(m.orden), 0) FROM MetodoPago m")
    int maxOrden();
}
