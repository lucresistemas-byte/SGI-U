package com.sgiu_group.sgiu.controllers.auth;

import com.sgiu_group.sgiu.models.dtos.CambioPasswordRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LoginRequestDTO;
import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.security.JwtUtil;
import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;

import java.util.Map;

/**
 * Controlador para manejar la autenticación y generación de tokens JWT.
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private EspUsuarioDetailsService usuarioDetailsService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private EspUsuarioRepository usuarioRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * Clase interna para representar una respuesta de login.
     */
    public static class LoginResponse {
        private String token;
        private Long id;
        private String username;
        private Boolean activo;
        private String rol;
        private Boolean requiereCambioPassword;

        public LoginResponse(String token, EspUsuario usuario) {
            this.token = token;
            this.id = usuario.getId();
            this.username = usuario.getUsername();
            this.activo = usuario.getActivo();
            this.rol = (usuario.getRol() != null && !usuario.getRol().isBlank()) ? usuario.getRol() : "ADMIN";
            this.requiereCambioPassword = Boolean.TRUE.equals(usuario.getRequiereCambioPassword());
        }

        public String getToken() {
            return token;
        }

        public Long getId() {
            return id;
        }

        public String getUsername() {
            return username;
        }

        public Boolean getActivo() {
            return activo;
        }

        public String getRol() {
            return rol;
        }

        public Boolean getRequiereCambioPassword() {
            return requiereCambioPassword;
        }
    }

    /**
     * Endpoint para autenticar usuario y generar token JWT.
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequestDTO request) {
        try {
            // Restauramos la validación estricta de credenciales
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.username(),
                            request.password()
                    )
            );
        }catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                 .body(Map.of("error", "Credenciales incorrectas"));
        }

        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(request.username());

        EspUsuario usuario = usuarioRepository.findByUsername(request.username());
        if (usuario == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Usuario no encontrado"));
        }

        final String jwt = jwtUtil.generateToken(userDetails);

        return ResponseEntity.ok(new LoginResponse(jwt, usuario));
    }

    /**
     * Endpoint para registrar un nuevo usuario (restringido a administradores).
     */
    @PostMapping("/register")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> register(@RequestBody LoginRequestDTO request) {
        if (usuarioRepository.findByUsername(request.username()) != null) {
            return ResponseEntity.badRequest().body(Map.of("error", "El nombre de usuario ya está en uso"));
        }

        EspUsuario usuario = new EspUsuario();
        usuario.setUsername(request.username());
        usuario.setPassword(passwordEncoder.encode(request.password()));
        usuario.setActivo(true);
        usuario.setRol("USER");
        usuario.setRequiereCambioPassword(false);

        usuarioRepository.save(usuario);

        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(usuario.getUsername());
        final String jwt = jwtUtil.generateToken(userDetails);

        return ResponseEntity.ok(new LoginResponse(jwt, usuario));
    }

    /**
     * Endpoint para cambiar contraseña de usuario autenticado.
     */
    @PostMapping("/cambiar-password")
    public ResponseEntity<?> cambiarPassword(
            @RequestBody CambioPasswordRequestDTO request,
            Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "No autenticado"));
        }

        String username = authentication.getName();
        EspUsuario usuario = usuarioRepository.findByUsername(username);
        if (usuario == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Usuario no encontrado"));
        }

        if (request.passwordNueva() == null || request.passwordNueva().trim().length() < 6) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "La nueva contraseña debe tener al menos 6 caracteres"));
        }

        if (!passwordEncoder.matches(request.passwordActual(), usuario.getPassword())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "La contraseña actual no es correcta"));
        }

        usuario.setPassword(passwordEncoder.encode(request.passwordNueva().trim()));
        usuario.setRequiereCambioPassword(false);
        usuarioRepository.save(usuario);

        return ResponseEntity.ok(Map.of("mensaje", "Contraseña actualizada exitosamente"));
    }
}