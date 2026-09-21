package com.sgiu_group.sgiu.models.dtos;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public record PedidoRequestDTO(
    @NotBlank(message = "El nombre del cliente es obligatorio")
    String clienteNombre,

    @NotBlank(message = "El teléfono del cliente es obligatorio")
    String clienteTelefono,

    @NotBlank(message = "La descripción del pedido es obligatoria")
    String descripcion,

    @NotNull(message = "El monto total es obligatorio")
    @DecimalMin(value = "0.01", message = "El monto total debe ser mayor a cero")
    BigDecimal montoTotal,

    @DecimalMin(value = "0.0", message = "La seña no puede ser negativa")
    BigDecimal senia,

    LocalDateTime fechaEntrega,

    String metodoPagoSenia
) {}
