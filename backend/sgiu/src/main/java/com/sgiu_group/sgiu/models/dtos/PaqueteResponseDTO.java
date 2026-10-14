package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.util.List;

/** Paquete con su armado: precio = costo del armado + monto fijo, redondeado hacia arriba a $100. */
public record PaqueteResponseDTO(
    Long id,
    String codigo,
    String nombre,
    Long categoriaId,
    String categoria,
    boolean activo,
    BigDecimal costoArmado,
    BigDecimal montoFijo,
    BigDecimal precioVenta,
    /** precioVenta − costoArmado. */
    BigDecimal gananciaPesos,
    Long stockActual,
    List<Fila> armado,
    /** Precios que cambiaron al guardar (resumen "Se actualizaron N precios"). */
    List<CambioPrecioDTO> cambiosDePrecio
) {
    public record Fila(
        Long id,
        Long articuloId,
        String articuloCodigo,
        String articuloNombre,
        BigDecimal cantidad,
        String unidadMedida,
        /** Costo por la unidad elegida. */
        BigDecimal costoUnitario,
        BigDecimal subtotal,
        String familia
    ) {}
}
