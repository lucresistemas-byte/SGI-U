package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * Servicio de detalles de usuario para cargar usuario específico basado en nombre de usuario.
 */
@Service
public class EspUsuarioDetailsService implements UserDetailsService {

    @Autowired
    private EspUsuarioRepository espUsuarioRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        EspUsuario usuario = espUsuarioRepository.findByUsername(username);
        if (usuario == null) {
            throw new UsernameNotFoundException("Usuario no encontrado: " + username);
        }
        String rol = (usuario.getRol() != null && !usuario.getRol().isBlank())
                ? usuario.getRol().trim().toUpperCase()
                : "USER";
        if (!rol.startsWith("ROLE_")) {
            rol = "ROLE_" + rol;
        }

        return org.springframework.security.core.userdetails.User.builder()
                .username(usuario.getUsername())
                .password(usuario.getPassword())
                .authorities(rol)
                .disabled(!usuario.getActivo())
                .build();
    }
}