package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.Pedido;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PedidoRepository extends JpaRepository<Pedido, Long> {
    List<Pedido> findByActivoTrueOrderByIdDesc();
}
