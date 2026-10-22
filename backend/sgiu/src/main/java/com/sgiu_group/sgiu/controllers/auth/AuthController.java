package com.sgiu_group.sgiu.controllers.auth;

import com.sgiu_group.sgiu.models.dtos.CambioPasswordRequestDTO;
import com.sgiu_group.sgiu.models.dtos.LoginRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecuperacionPasswordRequestDTO;
import com.sgiu_group.sgiu.models.entities.EspUsuario;
import com.sgiu_group.sgiu.repositories.EspUsuarioRepository;
import com.sgiu_group.sgiu.security.JwtUtil;
import com.sgiu_group.sgiu.security.RecoveryKeyService;
import com.sgiu_group.sgiu.services.EspUsuarioDetailsService;
import com.sgiu_group.sgiu.services.LoginAttemptService;
import lombok.extern.slf4j.Slf4j;
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
@Slf4j
@RestController
@RequestMapping("/api/auth")
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

    @Autowired
    private LoginAttemptService loginAttemptService;

    @Autowired
    private RecoveryKeyService recoveryKeyService;

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
     * A2: 5 credenciales incorrectas seguidas bloquean el login 15 minutos (429).
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequestDTO request) {
        if (loginAttemptService.estaBloqueado(request.username())) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("error", "Demasiados intentos fallidos. Intente de nuevo en "
                            + loginAttemptService.minutosRestantesDeBloqueo(request.username())
                            + " minutos."));
        }
        try {
            // Restauramos la validación estricta de credenciales
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.username(),
                            request.password()
                    )
            );
        }catch (BadCredentialsException e) {
            loginAttemptService.registrarFallo(request.username());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                 .body(Map.of("error", "Credenciales incorrectas"));
        }

        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(request.username());

        EspUsuario usuario = usuarioRepository.findByUsername(request.username());
        if (usuario == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Usuario no encontrado"));
        }

        loginAttemptService.registrarExito(request.username());

        // A2: el reclamo cambioPassword bloquea el resto de la API hasta
        // que el usuario cambie la contraseña de fábrica.
        final String jwt = jwtUtil.generateToken(userDetails,
                Boolean.TRUE.equals(usuario.getRequiereCambioPassword()));

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
        // A2: solo existe el rol ADMIN (decisión 2026-10-15).
        usuario.setRol("ADMIN");
        usuario.setRequiereCambioPassword(false);

        usuarioRepository.save(usuario);

        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(usuario.getUsername());
        final String jwt = jwtUtil.generateToken(userDetails, false);

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

        // A2: se devuelve un token nuevo SIN el reclamo cambioPassword,
        // para que el frontend continúe sin tener que volver a entrar.
        final UserDetails userDetails = usuarioDetailsService.loadUserByUsername(usuario.getUsername());
        final String jwt = jwtUtil.generateToken(userDetails, false);

        return ResponseEntity.ok(new LoginResponse(jwt, usuario));
    }

    /**
     * Recuperación offline de contraseña: requiere la clave de recuperación de
     * la instalación (archivo sgiu-recovery.key). Público, sin JWT, sin email.
     * El usuario inexistente, inactivo o con clave incorrecta reciben la misma
     * respuesta genérica (sin enumerar usuarios); 5 fallos bloquean 15 minutos.
     */
    @PostMapping("/recuperar-password")
    public ResponseEntity<?> recuperarPassword(@RequestBody RecuperacionPasswordRequestDTO request) {
        String username = request.username() == null ? "" : request.username().trim();
        String clave = request.claveRecuperacion() == null ? "" : request.claveRecuperacion().trim();
        String passwordNueva = request.passwordNueva() == null ? "" : request.passwordNueva().trim();

        if (username.isEmpty() || clave.isEmpty()) {
            return badRequest("Usuario y clave de recuperación son obligatorios", "DATOS_INCOMPLETOS");
        }
        if (passwordNueva.length() < 6) {
            return badRequest("La nueva contraseña debe tener al menos 6 caracteres", "PASSWORD_INVALIDA");
        }
        if (!recoveryKeyService.isReady()) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "No se pudo restablecer la contraseña. Intente nuevamente.",
                            "codigo", "RECUPERACION_NO_DISPONIBLE"));
        }

        final String claveIntentos = "recuperacion:" + username;
        if (loginAttemptService.estaBloqueado(claveIntentos)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("error", "Demasiados intentos. Intente de nuevo en "
                                    + loginAttemptService.minutosRestantesDeBloqueo(claveIntentos) + " minutos.",
                            "codigo", "DEMASIADOS_INTENTOS"));
        }

        // La clave se compara siempre (aunque el usuario no exista) para no
        // filtrar por tiempo de respuesta si el usuario existe.
        EspUsuario usuario = usuarioRepository.findByUsername(username);
        boolean claveOk = recoveryKeyService.coincide(clave);

        if (usuario == null || !Boolean.TRUE.equals(usuario.getActivo()) || !claveOk) {
            loginAttemptService.registrarFallo(claveIntentos);
            return badRequest("Usuario o clave de recuperación inválidos.", "RECUPERACION_INVALIDA");
        }

        usuario.setPassword(passwordEncoder.encode(passwordNueva));
        usuario.setRequiereCambioPassword(false);
        usuarioRepository.save(usuario);

        // Los fallos viejos de login no deben bloquear la contraseña nueva.
        loginAttemptService.registrarExito(username);
        loginAttemptService.registrarExito(claveIntentos);

        log.info("[AUTH] Contraseña restablecida con clave de recuperación para '{}'", username);

        return ResponseEntity.ok(Map.of(
                "mensaje", "Contraseña restablecida. Inicie sesión con la nueva contraseña.",
                "username", usuario.getUsername()));
    }

    private static ResponseEntity<?> badRequest(String mensaje, String codigo) {
        return ResponseEntity.badRequest().body(Map.of("error", mensaje, "codigo", codigo));
    }
}