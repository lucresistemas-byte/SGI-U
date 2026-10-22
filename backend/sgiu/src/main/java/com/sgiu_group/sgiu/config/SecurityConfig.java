package com.sgiu_group.sgiu.config;

import com.sgiu_group.sgiu.security.JwtFilter;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Configuración de seguridad de la aplicación.
 */
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Autowired
    private JwtFilter jwtFilter;

    /**
     * A2: Allowlist de orígenes CORS. En lugar de "*" se usa una lista
     * configurable por propiedad {@code sgiu.cors.allowed-origins}, para que
     * solo el frontend autorizado pueda llamar a la API desde un navegador.
     */
    @Value("${sgiu.cors.allowed-origins:http://localhost:5173,http://127.0.0.1:5173,http://localhost:8080,http://127.0.0.1:8080}")
    private List<String> allowedOrigins;

    /**
     * Configura la cadena de filtros de seguridad.
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // CORS restringido a la allowlist de orígenes (A2)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(authz -> authz
                // Rutas públicas (login, recuperación de contraseña y documentación)
                .requestMatchers("/api/auth/login", "/api/auth/recuperar-password", "/v2/api-docs",
                        "/swagger-ui/**").permitAll()
                // Nombre y logo para la pantalla de login (antes de tener token).
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/configuracion/marca").permitAll()
                // Registro de usuarios: restringido a rol ADMIN
                .requestMatchers("/api/auth/register").hasRole("ADMIN")
                // Todo lo demás requiere token JWT válido
                .anyRequest().authenticated()
            )
            // Headers de seguridad HTTP: HSTS, X-Frame-Options, CSP y nosniff (A2)
            .headers(headers -> headers
                .httpStrictTransportSecurity(hsts -> hsts
                        .includeSubDomains(true)
                        .maxAgeInSeconds(31536000))
                .frameOptions(frame -> frame.deny())
                .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'"))
                .contentTypeOptions(contentType -> {})
            )
            // Configuración del Entry Point para devolver 401 en JSON
            .exceptionHandling(ex -> ex.authenticationEntryPoint((request, response, authException) -> {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"No autorizado\"}");
            }))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Fuente de configuración CORS con la allowlist configurable.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(allowedOrigins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    /**
     * Bean para el codificador de contraseñas BCrypt.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Bean para el AuthenticationManager.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }
}
