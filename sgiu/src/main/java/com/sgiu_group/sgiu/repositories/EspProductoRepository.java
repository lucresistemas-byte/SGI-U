package com.sgiu_group.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface EspProductoRepository extends JpaRepository<EspProducto, Long> {

    Optional<EspProducto> findByCodigo(String codigo);
}
