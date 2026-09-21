package com.sgiu_group.sgiu.security;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EspUsuarioDetailsServiceTest {

    @Mock
    private EspUsuarioRepository usuarioRepository;

    @InjectMocks
    private EspUsuarioDetailsService service;

    @Test
    void loadUserByUsername_usuarioActivo_cargaDetallesConRolUsuarioHabilitado() {
        EspUsuario usuario = new EspUsuario("luciox", "{noop}clave", true);
        when(usuarioRepository.findByUsername("luciox")).thenReturn(usuario);

        UserDetails detalles = service.loadUserByUsername("luciox");

        assertThat(detalles.getUsername()).isEqualTo("luciox");
        assertThat(detalles.getPassword()).isEqualTo("{noop}clave");
        assertThat(detalles.isEnabled()).isTrue();
        assertThat(detalles.getAuthorities())
                .extracting(Object::toString)
                .containsExactly("ROLE_USER");
    }

    @Test
    void loadUserByUsername_usuarioInactivo_deshabilitaLaCuenta() {
        EspUsuario usuario = new EspUsuario("inactivo", "{noop}clave", false);
        when(usuarioRepository.findByUsername("inactivo")).thenReturn(usuario);

        UserDetails detalles = service.loadUserByUsername("inactivo");

        assertThat(detalles.isEnabled()).isFalse();
    }

    @Test
    void loadUserByUsername_usuarioInexistente_lanzaUsernameNotFound() {
        when(usuarioRepository.findByUsername("fantasma")).thenReturn(null);

        assertThatThrownBy(() -> service.loadUserByUsername("fantasma"))
                .isInstanceOf(UsernameNotFoundException.class)
                .hasMessageContaining("fantasma");
    }
}