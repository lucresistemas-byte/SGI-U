package com.sgiu_group.sgiu.models.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Entidad que representa un usuario del sistema.
 */
@Entity
@Table(name = "esp_usuarios", uniqueConstraints = @jakarta.persistence.UniqueConstraint(columnNames = "username"))
public class EspUsuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private Boolean activo;

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
        this.rol = "USER";
        this.requiereCambioPassword = false;
    }

    public EspUsuario(String username, String password, Boolean activo, String rol, Boolean requiereCambioPassword) {
        this.username = username;
        this.password = password;
        this.activo = activo;
        this.rol = rol;
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
        return rol;
    }

    public void setRol(String rol) {
        this.rol = rol;
    }

    public Boolean getRequiereCambioPassword() {
        return requiereCambioPassword;
    }

    public void setRequiereCambioPassword(Boolean requiereCambioPassword) {
        this.requiereCambioPassword = requiereCambioPassword;
    }
}