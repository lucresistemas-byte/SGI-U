package com.sgiu_group.sgiu.models.dtos;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record PedidoResponseDTO(
    Long id,
    String clienteNombre,
    String clienteTelefono,
    String descripcion,
    BigDecimal montoTotal,
    BigDecimal senia,
    BigDecimal saldo,
    String estado,
    LocalDateTime fechaCreacion,
    LocalDateTime fechaEntrega,
    List<PedidoAbonoDTO> abonos
) {}
