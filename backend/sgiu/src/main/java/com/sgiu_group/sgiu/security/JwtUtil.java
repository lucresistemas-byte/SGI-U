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

    /** A2: JWT de 8 horas (decisión del equipo 2026-10-15). */
    @Value("${jwt.expiration:28800000}")
    private long jwtExpiration = 28800000L;

    public long getJwtExpiration() {
        return jwtExpiration;
    }

    public void setJwtExpiration(long jwtExpiration) {
        this.jwtExpiration = jwtExpiration;
    }

    private String secretKey;
    private java.security.Key signingKey;
    private String lastResolvedSecret;

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
        } else if (configuredSecret != null && !configuredSecret.isBlank()) {
            secretToUse = configuredSecret;
        } else {
            // A2: sin secreto configurado, cada instalación usa el suyo
            // generado en InstallationSecrets (fuera del repo).
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

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    public String generateToken(UserDetails userDetails) {
        return generateToken(userDetails, false);
    }

    public String generateToken(UserDetails userDetails, boolean requiereCambioPassword) {
        Map<String, Object> claims = new HashMap<>();
        if (userDetails.getAuthorities() != null && !userDetails.getAuthorities().isEmpty()) {
            var roles = userDetails.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .toList();
            claims.put("roles", roles);
            String rol = roles.get(0).replace("ROLE_", "");
            claims.put("rol", rol);
        }
        claims.put("cambioPassword", requiereCambioPassword);
        return createToken(claims, userDetails.getUsername());
    }

    public boolean requiereCambioPassword(String token) {
        return Boolean.TRUE.equals(extractClaim(token, claims -> claims.get("cambioPassword", Boolean.class)));
    }

    public String generateToken(Map<String, Object> extraClaims, String username) {
        return createToken(extraClaims, username);
    }

    private String createToken(Map<String, Object> extraClaims, String subject) {
        return Jwts.builder()
                .setClaims(extraClaims)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    public boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
}
