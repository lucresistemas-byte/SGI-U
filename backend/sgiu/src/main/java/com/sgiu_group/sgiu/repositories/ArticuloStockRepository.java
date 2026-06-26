package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ArticuloStockRepository extends JpaRepository<ArticuloStock, Long> {

    Optional<ArticuloStock> findByEspProducto(EspProducto espProducto);

    Optional<ArticuloStock> findByEspProducto_Codigo(String codigo);

    @Query("SELECT COUNT(a) FROM ArticuloStock a WHERE a.cantidad <= a.stockMinimo")
    Long countProductosConStockCritico();

    @Query("SELECT a.espProducto.id, p.nombre, a.cantidad, a.stockMinimo " +
           "FROM ArticuloStock a JOIN a.espProducto p " +
           "WHERE a.cantidad <= a.stockMinimo " +
           "ORDER BY a.cantidad ASC")
    List<Object[]> findProductosConStockCriticoDetallado();
}
