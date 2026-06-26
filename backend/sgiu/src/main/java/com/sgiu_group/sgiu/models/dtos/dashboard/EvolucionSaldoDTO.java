package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;
import java.time.LocalDate;

public class EvolucionSaldoDTO {
    private LocalDate fecha;
    private BigDecimal saldoNeto;

    public EvolucionSaldoDTO(LocalDate fecha, BigDecimal saldoNeto) {
        this.fecha = fecha;
        this.saldoNeto = saldoNeto;
    }

    public LocalDate getFecha() { return fecha; }
    public BigDecimal getSaldoNeto() { return saldoNeto; }
}
