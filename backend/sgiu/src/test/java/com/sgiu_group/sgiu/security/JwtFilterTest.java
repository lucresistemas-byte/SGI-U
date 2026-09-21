package com.sgiu_group.sgiu.security;

import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.PrintWriter;
import java.io.StringWriter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JwtFilterTest {

    @Mock
    private JwtUtil jwtUtil;
    @Mock
    private EspUsuarioDetailsService espUsuarioDetailsService;
    @Mock
    private HttpServletRequest request;
    @Mock
    private HttpServletResponse response;
    @Mock
    private FilterChain filterChain;
    @Mock
    private UserDetails userDetails;

    private JwtFilter jwtFilter;

    @BeforeEach
    void setUp() {
        jwtFilter = new JwtFilter();
        ReflectionTestUtils.setField(jwtFilter, "jwtUtil", jwtUtil);
        ReflectionTestUtils.setField(jwtFilter, "espUsuarioDetailsService", espUsuarioDetailsService);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void sinHeaderAuthorization_continuaLaCadenaSinAutenticar() throws Exception {
        when(request.getHeader("Authorization")).thenReturn(null);

        jwtFilter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(espUsuarioDetailsService);
    }

    @Test
    void headerSinPrefijoBearer_continuaLaCadena() throws Exception {
        when(request.getHeader("Authorization")).thenReturn("Basic dXN1YXJpbzpwYXNz");

        jwtFilter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void tokenValido_configuraLaAutenticacion() throws Exception {
        when(request.getHeader("Authorization")).thenReturn("Bearer token-1234");
        when(jwtUtil.extractUsername("token-1234")).thenReturn("luciox");
        when(espUsuarioDetailsService.loadUserByUsername("luciox")).thenReturn(userDetails);
        when(jwtUtil.validateToken("token-1234", userDetails)).thenReturn(true);

        jwtFilter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getPrincipal())
                .isSameAs(userDetails);
    }

    @Test
    void tokenInvalido_responde401YCortaLaCadena() throws Exception {
        when(request.getHeader("Authorization")).thenReturn("Bearer token-roto");
        when(jwtUtil.extractUsername("token-roto"))
                .thenThrow(new io.jsonwebtoken.MalformedJwtException("token inválido"));

        StringWriter sw = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(sw));

        jwtFilter.doFilterInternal(request, response, filterChain);

        verify(response).setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        verify(response).setContentType("application/json");
        verify(filterChain, never()).doFilter(request, response);
        assertThat(sw.toString()).contains("Token inválido o expirado");
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void tokenDeUsuarioInexistente_responde401 () throws Exception {
        when(request.getHeader("Authorization")).thenReturn("Bearer token-x");
        when(jwtUtil.extractUsername("token-x")).thenReturn("fantasma");
        when(espUsuarioDetailsService.loadUserByUsername(anyString()))
                .thenThrow(new org.springframework.security.core.userdetails.UsernameNotFoundException("no"));

        StringWriter sw = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(sw));

        jwtFilter.doFilterInternal(request, response, filterChain);

        verify(response).setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        verify(filterChain, never()).doFilter(request, response);
    }
}