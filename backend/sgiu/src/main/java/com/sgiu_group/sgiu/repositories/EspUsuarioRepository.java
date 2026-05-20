package com.sgiu_group.sgiu.repositories;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio para operaciones CRUD sobre la entidad EspUsuario.
 */
@Repository
public interface EspUsuarioRepository extends JpaRepository<EspUsuario, Long> {

    /**
     * Busca un usuario por su nombre de usuario.
     * 
     * @param username Nombre de usuario a buscar
     * @return Usuario encontrado o null si no existe
     */
    EspUsuario findByUsername(String username);
}