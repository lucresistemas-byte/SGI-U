package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "categorias",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_categoria_nombre", columnNames = "nombre")
    }
)
public class Categoria extends BaseEntity {

    @Column(nullable = false, length = 50)
    private String nombre;

    @Column(length = 255)
    private String descripcion;

    @Column(nullable = false)
    private boolean activo = true;

    public Categoria() {
        this.activo = true;
    }

    public Categoria(String nombre) {
        this.nombre = nombre;
        this.activo = true;
    }

    public Categoria(String nombre, String descripcion) {
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.activo = true;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }
}
