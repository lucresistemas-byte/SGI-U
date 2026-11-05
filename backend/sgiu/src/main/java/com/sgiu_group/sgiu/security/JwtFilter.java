package com.sgiu_group.sgiu.security;

import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
/**
 * Filtro para interceptar peticiones y validar el token JWT.
 * <p>
 * Si el token trae el reclamo {@code cambioPassword=true} (primer uso con la
 * contraseña de fábrica), solo se deja pasar {@code /api/auth/cambiar-password};
 * el resto de la API responde 403 con {@code REQUIERE_CAMBIO_PASSWORD}.
 */
@Component
public class JwtFilter extends OncePerRequestFilter {

    /** Rutas permitidas con el reclamo de cambio de contraseña pendiente. */
    private static final List<String> RUTAS_CAMBIO_PASSWORD_PERMITIDAS =
            List.of("/api/auth/cambiar-password");

    /**
     * Rutas públicas donde un token (válido o vencido) no debe influir: el
     * frontend inyecta el token en cada petición y un token vencido aquí
     * devolvería 401 antes de llegar al controller.
     */
    private static final List<String> RUTAS_PUBLICAS_SIN_TOKEN =
            List.of("/api/auth/recuperar-password");

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private EspUsuarioDetailsService espUsuarioDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Rutas públicas: se ignoran los tokens por más vencidos que estén.
        if (esRutaPublicaSinToken(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            final String authorizationHeader = request.getHeader("Authorization");

            String username = null;
            String jwt = null;

            if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
                jwt = authorizationHeader.substring(7);
                username = jwtUtil.extractUsername(jwt);
            }

            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = this.espUsuarioDetailsService.loadUserByUsername(username);

                if (jwtUtil.validateToken(jwt, userDetails)) {
                    // A2: si la contraseña de fábrica sigue vigente, solo se
                    // permite cambiarla; nada más de la API está disponible.
                    if (jwtUtil.requiereCambioPassword(jwt)
                            && !esRutaPermitidaCambioPassword(request)) {
                        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        response.setContentType("application/json");
                        response.getWriter().write(
                                "{\"error\":\"REQUIERE_CAMBIO_PASSWORD\",\"mensaje\":\"Debe cambiar la contraseña antes de usar el sistema\"}");
                        response.getWriter().flush();
                        return;
                    }

                    UsernamePasswordAuthenticationToken usernamePasswordAuthenticationToken = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    usernamePasswordAuthenticationToken
                            .setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(usernamePasswordAuthenticationToken);
                }
            }
            filterChain.doFilter(request, response);

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"Token inválido o expirado\"}");
            response.getWriter().flush();
            // No se invoca filterChain.doFilter para cortar la cadena
        }
    }

    private static boolean esRutaPermitidaCambioPassword(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return RUTAS_CAMBIO_PASSWORD_PERMITIDAS.stream().anyMatch(uri::endsWith);
    }

    /** Null-check necesario: los tests no stubbean getRequestURI(). */
    private static boolean esRutaPublicaSinToken(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri != null && RUTAS_PUBLICAS_SIN_TOKEN.stream().anyMatch(uri::endsWith);
    }
}
