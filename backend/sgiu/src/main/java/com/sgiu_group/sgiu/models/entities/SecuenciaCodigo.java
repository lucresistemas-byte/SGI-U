package com.sgiu_group.sgiu.models.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Último número usado para cada prefijo de código (ELA, REV, MP, ...). */
@Entity
@Table(name = "secuencias_codigo")
@Getter
@Setter
@NoArgsConstructor
public class SecuenciaCodigo {

    @Id
    @Column(length = 10)
    private String prefijo;

    @Column(nullable = false)
    private int ultimo;

    public SecuenciaCodigo(String prefijo, int ultimo) {
        this.prefijo = prefijo;
        this.ultimo = ultimo;
    }
}
