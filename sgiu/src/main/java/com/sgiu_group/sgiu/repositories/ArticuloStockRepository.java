package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ArticuloStockRepository extends JpaRepository<ArticuloStock, Long> {

    Optional<ArticuloStock> findByEspProducto(EspProducto espProducto);
}