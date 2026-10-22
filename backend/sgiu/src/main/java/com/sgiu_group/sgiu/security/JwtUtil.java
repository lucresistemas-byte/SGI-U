package com.sgiu_group.sgiu.security;

import com.sgiu_group.sgiu.InstallationSecrets;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * Utilidad para generar y validar tokens JWT.
 * Configurado con expiración de 8 horas (28.800.000 ms) según RFC 8725 y OWASP ASVS v4.0.
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret:}")
    private String configuredSecret;

    @Value("${jwt.expiration:28800000}")
    private long jwtExpiration = 28800000L;

    private String secretKey;
    private java.security.Key signingKey;
    private String lastResolvedSecret;

    public long getJwtExpiration() {
        return jwtExpiration;
    }

    public void setJwtExpiration(long jwtExpiration) {
        this.jwtExpiration = jwtExpiration;
    }

    @PostConstruct
    public void init() {
        resolveSigningKey();
    }

    private synchronized java.security.Key getSigningKey() {
        if (this.signingKey == null || (this.secretKey != null && !this.secretKey.equals(this.lastResolvedSecret))) {
            resolveSigningKey();
        }
        return this.signingKey;
    }

    private void resolveSigningKey() {
        String secretToUse;
        if (this.secretKey != null && !this.secretKey.isBlank()) {
            secretToUse = this.secretKey;
        } else if (configuredSecret != null && !configuredSecret.isBlank()
                && !configuredSecret.equals("a7b8C9d0E1f2G3h4I5j6K7l8M9n0O1p2Q3r4S5t6U7v=")) {
            secretToUse = configuredSecret;
        } else {
            secretToUse = InstallationSecrets.getOrCreateJwtSecret();
        }

        this.secretKey = secretToUse;
        this.lastResolvedSecret = secretToUse;

        byte[] keyBytes;
        try {
            keyBytes = io.jsonwebtoken.io.Decoders.BASE64.decode(secretToUse);
        } catch (Exception e1) {
            try {
                keyBytes = io.jsonwebtoken.io.Decoders.BASE64URL.decode(secretToUse);
            } catch (Exception e2) {
                keyBytes = secretToUse.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            }
        }
        if (keyBytes.length < 32) {
            keyBytes = java.util.Arrays.copyOf(keyBytes, 32);
        }
        this.signingKey = io.jsonwebtoken.security.Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Extrae el nombre de usuario del token.
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Extrae una reclamo específico del token.
     */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    /**
     * Genera un token JWT para los detalles del usuario proporcionados incluyendo roles.
     */
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        if (userDetails.getAuthorities() != null && !userDetails.getAuthorities().isEmpty()) {
            var roles = userDetails.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .toList();
            claims.put("roles", roles);
            String rol = roles.get(0).replace("ROLE_", "");
            claims.put("rol", rol);
        }
        return createToken(claims, userDetails.getUsername());
    }

    /**
     * Genera un token JWT con reclamos personalizados.
     */
    public String generateToken(Map<String, Object> extraClaims, String username) {
        return createToken(extraClaims, username);
    }

    /**
     * Crea el token JWT con los reclamos proporcionados.
     */
    private String createToken(Map<String, Object> extraClaims, String subject) {
        return Jwts.builder()
                .setClaims(extraClaims)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * Extrae todos los reclamos del token.
     */
    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /**
     * Valida el token contra los detalles del usuario.
     */
    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    /**
     * Verifica si el token ha expirado.
     */
    public boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    /**
     * Extrae la fecha de expiración del token.
     */
    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
}
