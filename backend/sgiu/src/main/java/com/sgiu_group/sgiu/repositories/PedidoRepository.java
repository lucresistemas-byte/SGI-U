package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.Pedido;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PedidoRepository extends JpaRepository<Pedido, Long> {
    List<Pedido> findByActivoTrueOrderByIdDesc();

    @Query("SELECT p FROM Pedido p WHERE p.activo = true AND " +
           "(LOWER(p.clienteNombre) LIKE LOWER(CONCAT('%', :q, '%')) OR p.clienteTelefono LIKE CONCAT('%', :q, '%')) " +
           "ORDER BY p.id DESC")
    List<Pedido> buscarPorNombreOTelefono(@Param("q") String q);
}
