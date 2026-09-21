package com.sgiu_group.sgiu.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtUtilTest {

    private static final String SECRET =
            "claveDePruebaSuperSeguraQueCumplaLos256BitsNecesariosParaHS256!";

    private JwtUtil jwtUtil;

    private final UserDetails usuario = User.withUsername("luciox")
            .password("secreto")
            .roles("USER")
            .build();

    private final UserDetails otroUsuario = User.withUsername("otro")
            .password("secreto")
            .roles("USER")
            .build();

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil();
        ReflectionTestUtils.setField(jwtUtil, "secretKey", SECRET);
        ReflectionTestUtils.setField(jwtUtil, "jwtExpiration", 3_600_000L);
    }

    @Test
    void generateToken_devuelveUnTokenConElUsernameComoSubject() {
        String token = jwtUtil.generateToken(usuario);

        assertThat(token).isNotBlank();
        assertThat(jwtUtil.extractUsername(token)).isEqualTo("luciox");
    }

    @Test
    void generateToken_conClaimsExtra_losConserva() {
        String token = jwtUtil.generateToken(java.util.Map.of("rol", "ADMIN"), "luciox");
        String rol = jwtUtil.extractClaim(token, claims -> claims.get("rol", String.class));

        assertThat(jwtUtil.extractUsername(token)).isEqualTo("luciox");
        assertThat(rol).isEqualTo("ADMIN");
    }

    @Test
    void validateToken_tokenValidoParaElMismoUsuario_devuelveTrue() {
        String token = jwtUtil.generateToken(usuario);

        assertThat(jwtUtil.validateToken(token, usuario)).isTrue();
    }

    @Test
    void validateToken_tokenDeOtroUsuario_devuelveFalse() {
        String token = jwtUtil.generateToken(usuario);

        assertThat(jwtUtil.validateToken(token, otroUsuario)).isFalse();
    }

    @Test
    void validateToken_tokenExpirado_lanzaExpiredJwtException() {
        ReflectionTestUtils.setField(jwtUtil, "jwtExpiration", -10_000L);
        String token = jwtUtil.generateToken(usuario);

        assertThatThrownBy(() -> jwtUtil.validateToken(token, usuario))
                .isInstanceOf(io.jsonwebtoken.ExpiredJwtException.class);
    }

    @Test
    void extractUsername_tokenMalFormado_lanzaExcepcion() {
        assertThatThrownBy(() -> jwtUtil.extractUsername("no-es-un-token"))
                .isInstanceOfAny(io.jsonwebtoken.JwtException.class, RuntimeException.class);
    }
}