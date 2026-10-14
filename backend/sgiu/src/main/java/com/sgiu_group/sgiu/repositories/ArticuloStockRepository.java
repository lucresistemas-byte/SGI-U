package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface ArticuloStockRepository extends JpaRepository<ArticuloStock, Long> {

    Optional<ArticuloStock> findByEspProducto(EspProducto espProducto);

    Optional<ArticuloStock> findByEspProducto_Codigo(String codigo);

    List<ArticuloStock> findByEspProductoIn(Collection<EspProducto> productos);

    /** Stock bajo el mínimo de los artículos de los tipos dados (los que se venden, en el dashboard). */
    @Query("SELECT a FROM ArticuloStock a JOIN FETCH a.espProducto p " +
           "WHERE p.tipo IN :tipos AND a.cantidad <= a.stockMinimo " +
           "ORDER BY a.cantidad ASC")
    List<ArticuloStock> findStockCritico(@Param("tipos") Collection<TipoArticulo> tipos);
}
