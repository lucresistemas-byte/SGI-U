package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Método de pago configurable. El fijo es "Efectivo": no se renombra ni se
 * desactiva, y es el único que admite vuelto en el POS.
 */
@Entity
@Table(name = "metodos_pago",
       uniqueConstraints = @UniqueConstraint(name = "uk_metodo_pago_nombre", columnNames = "nombre"))
@Getter
@Setter
@NoArgsConstructor
public class MetodoPago extends BaseEntity {

    @Column(nullable = false, length = 50)
    private String nombre;

    @Column(nullable = false)
    private boolean activo = true;

    @Column(nullable = false)
    private boolean fijo = false;

    @Column(nullable = false)
    private int orden;

    public MetodoPago(String nombre, boolean fijo, int orden) {
        this.nombre = nombre;
        this.fijo = fijo;
        this.orden = orden;
    }

    /** Efectivo: el método fijo, con el que se da vuelto. */
    public boolean esEfectivo() {
        return fijo;
    }
}
