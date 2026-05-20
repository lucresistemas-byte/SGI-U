package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;

public record ProductoCatalogoDTO(
    String codigo,
    String nombre,
    BigDecimal precioUnitario,
    Long stockActual,
<<<<<<< HEAD
<<<<<<< HEAD
    boolean activo
=======
    Boolean activo // <-- NUEVO: Fundamental para el frontend
>>>>>>> origin/iteracion-2-frontend
=======
    Boolean activo // <-- NUEVO: Fundamental para el frontend
>>>>>>> b8680ed (feat: agregar login)
) {}