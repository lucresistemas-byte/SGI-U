package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

@Entity
@Table(name = "ventas")
public class Venta extends BaseEntity {

    // Mapeo de fecha_hora: obligatorio para el registro comercial
    @Column(name = "fecha_hora", nullable = false)
    private LocalDateTime fechaHora;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    // --- ANCLAJES DE ESCALABILIDAD (Campos Opcionales) ---
    
    @Column(name = "id_sesion_caja")
    private Integer idSesionCaja;

    @Column(name = "creado_por_usuario")
    private Integer creadoPorUsuario;

    // --- RELACIONES ---

    @OneToMany(
        mappedBy = "venta",
        cascade = CascadeType.ALL,
        orphanRemoval = true
    )
    private List<LineaVenta> lineas = new ArrayList<>();

    public Venta() {
        // Inicialización por defecto al crear la entidad
        this.fechaHora = LocalDateTime.now();
        this.total = BigDecimal.ZERO;
    }

    // --- GETTERS Y SETTERS ---

    public LocalDateTime getFechaHora() {
        return fechaHora;
    }

    public void setFechaHora(LocalDateTime fechaHora) {
        this.fechaHora = fechaHora;
    }

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }

    public Integer getIdSesionCaja() {
        return idSesionCaja;
    }

    public void setIdSesionCaja(Integer idSesionCaja) {
        this.idSesionCaja = idSesionCaja;
    }

    public Integer getCreadoPorUsuario() {
        return creadoPorUsuario;
    }

    public void setCreadoPorUsuario(Integer creadoPorUsuario) {
        this.creadoPorUsuario = creadoPorUsuario;
    }

    public List<LineaVenta> getLineas() {
        return lineas;
    }

    public void setLineas(List<LineaVenta> lineas) {
        this.lineas = lineas;
    }

    // --- MÉTODOS AUXILIARES (Sincronización Bidireccional) ---

    public void addLinea(LineaVenta linea) {
        lineas.add(linea);
        linea.setVenta(this);
    }

    public void removeLinea(LineaVenta linea) {
        lineas.remove(linea);
        linea.setVenta(null);
    }
}