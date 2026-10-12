package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.SecuenciaCodigo;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface SecuenciaCodigoRepository extends JpaRepository<SecuenciaCodigo, String> {

    /** SELECT ... FOR UPDATE: la fila queda bloqueada hasta el fin de la transacción. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM SecuenciaCodigo s WHERE s.prefijo = :prefijo")
    Optional<SecuenciaCodigo> bloquear(@Param("prefijo") String prefijo);
}
