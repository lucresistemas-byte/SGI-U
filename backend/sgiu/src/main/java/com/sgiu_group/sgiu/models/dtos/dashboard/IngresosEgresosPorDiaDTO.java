package com.sgiu_group.sgiu.models.dtos.dashboard;

import java.math.BigDecimal;
import java.time.LocalDate;

public class IngresosEgresosPorDiaDTO {
    private LocalDate fecha;
    private BigDecimal ingresos;
    private BigDecimal egresos;

    public IngresosEgresosPorDiaDTO(LocalDate fecha, BigDecimal ingresos, BigDecimal egresos) {
        this.fecha = fecha;
        this.ingresos = ingresos;
        this.egresos = egresos;
    }

    public LocalDate getFecha() { return fecha; }
    public BigDecimal getIngresos() { return ingresos; }
    public BigDecimal getEgresos() { return egresos; }
}
