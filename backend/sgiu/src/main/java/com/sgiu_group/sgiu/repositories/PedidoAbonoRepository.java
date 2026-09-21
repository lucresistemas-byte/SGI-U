package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.PedidoAbono;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PedidoAbonoRepository extends JpaRepository<PedidoAbono, Long> {
    List<PedidoAbono> findByPedido_IdOrderByIdAsc(Long pedidoId);
}
