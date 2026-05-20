package com.sgiu_group.sgiu.controllers.auth;

import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.security.JwtUtil;
import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

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
     * Clase interna para representar una solicitud de login.
     */
    public static class LoginRequest {
        private String username;
        private String password;

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }
    }

    /**
     * Clase interna para representar una respuesta de login.
     */
    public static class LoginResponse {
        private String token;
        private Long id;
        private String username;
        private Boolean activo;

        public LoginResponse(String token, EspUsuario usuario) {
            this.token = token;
            this.id = usuario.getId();
            this.username = usuario.getUsername();
            this.activo = usuario.getActivo();
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
    }

    /**
     * Endpoint para autenticar usuario y generar token JWT.
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        try {
            // Autenticar con Spring Security
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getUsername(),
                            loginRequest.getPassword()
                    )
            );
        } catch (BadCredentialsException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Credenciales incorrectas"));
        }

        // Cargar detalles del usuario
        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(loginRequest.getUsername());
        
        // Obtener usuario de la base de datos
        EspUsuario usuario = usuarioRepository.findByUsername(loginRequest.getUsername());
        if (usuario == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Usuario no encontrado"));
        }

        // Generar token JWT
        final String jwt = jwtUtil.generateToken(userDetails);

        // Devolver respuesta
        return ResponseEntity.ok(new LoginResponse(jwt, usuario));
    }

    /**
     * Endpoint para registrar un nuevo usuario (opcional).
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody LoginRequest registerRequest) {
        // Verificar si el usuario ya existe
        if (usuarioRepository.findByUsername(registerRequest.getUsername()) != null) {
            return ResponseEntity.badRequest().body(Map.of("error", "El nombre de usuario ya está en uso"));
        }

        // Crear nuevo usuario
        EspUsuario usuario = new EspUsuario();
        usuario.setUsername(registerRequest.getUsername());
        usuario.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        usuario.setActivo(true);

        // Guardar usuario
        usuarioRepository.save(usuario);

        // Generar token para el nuevo usuario
        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(usuario.getUsername());
        final String jwt = jwtUtil.generateToken(userDetails);

        // Devolver respuesta
        return ResponseEntity.ok(new LoginResponse(jwt, usuario));
    }
}