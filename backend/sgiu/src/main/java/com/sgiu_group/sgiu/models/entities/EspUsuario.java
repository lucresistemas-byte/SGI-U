package com.sgiu_group.sgiu.models.entities;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "esp_usuarios")
public class EspUsuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre de usuario es obligatorio")
    @Size(min = 3, max = 50, message = "El nombre de usuario debe tener entre 3 y 50 caracteres")
    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres")
    @Column(nullable = false)
    private String password;

    @NotNull(message = "El estado activo es obligatorio")
    @Column(nullable = false)
    private Boolean activo = true;

    /**
     * SGI-U opera con rol único ADMIN (single-admin / permisos simples).
     */
    @Column(nullable = false, length = 20)
    private String rol = "ADMIN";

    @Column(name = "requiere_cambio_password", nullable = false)
    private Boolean requiereCambioPassword = false;

    // Constructors
    public EspUsuario() {
    }

    public EspUsuario(String username, String password, Boolean activo) {
        this.username = username;
        this.password = password;
        this.activo = activo;
        this.rol = "ADMIN";
        this.requiereCambioPassword = false;
    }

    public EspUsuario(String username, String password, Boolean activo, String rol, Boolean requiereCambioPassword) {
        this.username = username;
        this.password = password;
        this.activo = activo;
        this.rol = (rol != null && !rol.isBlank()) ? rol : "ADMIN";
        this.requiereCambioPassword = requiereCambioPassword;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

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

    public Boolean getActivo() {
        return activo;
    }

    public void setActivo(Boolean activo) {
        this.activo = activo;
    }

    public String getRol() {
        return (rol != null && !rol.isBlank()) ? rol : "ADMIN";
    }

    public void setRol(String rol) {
        this.rol = (rol != null && !rol.isBlank()) ? rol : "ADMIN";
    }

    public Boolean getRequiereCambioPassword() {
        return requiereCambioPassword;
    }

    public void setRequiereCambioPassword(Boolean requiereCambioPassword) {
        this.requiereCambioPassword = requiereCambioPassword;
    }
}
