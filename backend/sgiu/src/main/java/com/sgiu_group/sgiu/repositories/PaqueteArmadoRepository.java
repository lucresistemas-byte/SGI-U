package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.PaqueteArmado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PaqueteArmadoRepository extends JpaRepository<PaqueteArmado, Long> {

    List<PaqueteArmado> findByPaqueteOrderById(EspProducto paquete);

    void deleteByPaquete(EspProducto paquete);

    /** Paquetes (activos o no) cuyo armado usa el artículo. */
    @Query("SELECT DISTINCT a.paquete FROM PaqueteArmado a WHERE a.articulo.id = :articuloId")
    List<EspProducto> findPaquetesQueUsan(@Param("articuloId") Long articuloId);
}
