package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.PedidoInvalidoException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.*;
import com.sgiu_group.sgiu.models.entities.EstadoPedido;
import com.sgiu_group.sgiu.models.entities.Pedido;
import com.sgiu_group.sgiu.models.entities.PedidoAbono;
import com.sgiu_group.sgiu.repositories.PedidoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository pedidoRepository;

    @Transactional(readOnly = true)
    public List<PedidoResponseDTO> buscarPedidos(String q) {
        List<Pedido> pedidos;
        if (q != null && !q.isBlank()) {
            pedidos = pedidoRepository.buscarPorNombreOTelefono(q.trim());
        } else {
            pedidos = pedidoRepository.findByActivoTrueOrderByIdDesc();
        }
        return pedidos.stream().map(this::toResponseDTO).toList();
    }

    @Transactional(readOnly = true)
    public PedidoResponseDTO obtenerPorId(Long id) {
        Pedido pedido = pedidoRepository.findById(id)
                .filter(Pedido::isActivo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Pedido no encontrado con ID: " + id));
        return toResponseDTO(pedido);
    }

    @Transactional
    public PedidoResponseDTO crearPedido(PedidoRequestDTO dto) {
        if (dto.montoTotal() == null || dto.montoTotal().compareTo(BigDecimal.ZERO) <= 0) {
            throw new PedidoInvalidoException("El monto total del pedido debe ser mayor a cero");
        }

        BigDecimal senia = dto.senia() != null ? dto.senia() : BigDecimal.ZERO;
        if (senia.compareTo(BigDecimal.ZERO) < 0) {
            throw new PedidoInvalidoException("La seña no puede ser negativa");
        }
        if (senia.compareTo(dto.montoTotal()) > 0) {
            throw new PedidoInvalidoException("La seña no puede ser mayor al monto total del pedido");
        }

        Pedido pedido = new Pedido(
                dto.clienteNombre().trim(),
                dto.clienteTelefono().trim(),
                dto.descripcion().trim(),
                dto.montoTotal(),
                senia,
                dto.fechaEntrega()
        );

        if (senia.compareTo(BigDecimal.ZERO) > 0) {
            String metodo = dto.metodoPagoSenia() != null && !dto.metodoPagoSenia().isBlank()
                    ? dto.metodoPagoSenia().trim().toUpperCase()
                    : "EFECTIVO";
            PedidoAbono abonoInicial = new PedidoAbono(pedido, senia, metodo, "Seña inicial del pedido");
            pedido.addAbono(abonoInicial);
        }

        Pedido guardado = pedidoRepository.save(pedido);
        log.info("[PEDIDO] Creado pedido ID {} para '{}'. Monto: ${}, Seña: ${}, Saldo: ${}, Estado: {}",
                guardado.getId(), guardado.getClienteNombre(), guardado.getMontoTotal(), guardado.getSenia(), guardado.getSaldo(), guardado.getEstado());

        return toResponseDTO(guardado);
    }

    @Transactional
    public PedidoResponseDTO abonarSaldo(Long id, AbonoRequestDTO dto) {
        Pedido pedido = pedidoRepository.findById(id)
                .filter(Pedido::isActivo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Pedido no encontrado con ID: " + id));

        if (pedido.getEstado() != EstadoPedido.PENDIENTE) {
            throw new PedidoInvalidoException("No se pueden registrar abonos a un pedido en estado " + pedido.getEstado());
        }

        if (dto.monto() == null || dto.monto().compareTo(BigDecimal.ZERO) <= 0) {
            throw new PedidoInvalidoException("El monto a abonar debe ser mayor a cero");
        }

        if (dto.monto().compareTo(pedido.getSaldo()) > 0) {
            throw new PedidoInvalidoException("El monto a abonar ($" + dto.monto() + ") excede el saldo pendiente ($" + pedido.getSaldo() + ")");
        }

        // Registrar abono
        String metodo = dto.metodoPago() != null && !dto.metodoPago().isBlank()
                ? dto.metodoPago().trim().toUpperCase()
                : "EFECTIVO";
        PedidoAbono abono = new PedidoAbono(pedido, dto.monto(), metodo, dto.nota());
        pedido.addAbono(abono);

        // Descontar saldo
        BigDecimal nuevoSaldo = pedido.getSaldo().subtract(dto.monto());
        pedido.setSaldo(nuevoSaldo);

        // Si se salda la totalidad, el pedido pasa a PAGADO (sin crear Venta nueva - Decisión D6)
        if (nuevoSaldo.compareTo(BigDecimal.ZERO) == 0) {
            pedido.setEstado(EstadoPedido.PAGADO);
            log.info("[PEDIDO] Pedido ID {} totalmente saldado. Nuevo estado: PAGADO", pedido.getId());
        } else {
            log.info("[PEDIDO] Abono de ${} registrado para pedido ID {}. Saldo restante: ${}",
                    dto.monto(), pedido.getId(), nuevoSaldo);
        }

        Pedido guardado = pedidoRepository.save(pedido);
        return toResponseDTO(guardado);
    }

    @Transactional
    public PedidoResponseDTO cancelarPedido(Long id) {
        Pedido pedido = pedidoRepository.findById(id)
                .filter(Pedido::isActivo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Pedido no encontrado con ID: " + id));

        if (pedido.getEstado() == EstadoPedido.PAGADO) {
            throw new PedidoInvalidoException("No se puede cancelar un pedido que ya ha sido completamente pagado");
        }

        pedido.setEstado(EstadoPedido.CANCELADO);
        Pedido guardado = pedidoRepository.save(pedido);
        log.info("[PEDIDO] Cancelado pedido ID {}", id);
        return toResponseDTO(guardado);
    }

    public PedidoResponseDTO toResponseDTO(Pedido p) {
        List<PedidoAbonoDTO> abonosDTO = p.getAbonos().stream()
                .map(a -> new PedidoAbonoDTO(
                        a.getId(),
                        a.getMonto(),
                        a.getMetodoPago(),
                        a.getNota(),
                        a.getCreatedAt()
                ))
                .toList();

        return new PedidoResponseDTO(
                p.getId(),
                p.getClienteNombre(),
                p.getClienteTelefono(),
                p.getDescripcion(),
                p.getMontoTotal(),
                p.getSenia(),
                p.getSaldo(),
                p.getEstado().name(),
                p.getCreatedAt(),
                p.getFechaEntrega(),
                abonosDTO
        );
    }
}
