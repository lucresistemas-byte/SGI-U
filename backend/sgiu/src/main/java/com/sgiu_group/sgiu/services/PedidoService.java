package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.PedidoInvalidoException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.*;
import com.sgiu_group.sgiu.models.entities.EstadoPedido;
import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.models.entities.Pedido;
import com.sgiu_group.sgiu.models.entities.PedidoAbono;
import com.sgiu_group.sgiu.repositories.PedidoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository pedidoRepository;
    private final MetodoPagoService metodoPagoService;

    @Transactional(readOnly = true)
    public List<PedidoResponseDTO> buscarPedidos(String q) {
        List<Pedido> pedidos = pedidoRepository.findByActivoTrueOrderByIdDesc();
        if (q != null && !q.isBlank()) {
            pedidos = pedidos.stream().filter(p -> coincide(p, q.trim())).toList();
        }
        return pedidos.stream().map(this::toResponseDTO).toList();
    }

    /**
     * Busca en nombre y descripción (sin distinguir mayúsculas) y en el
     * teléfono comparando solo dígitos: "1155550001" encuentra "11-5555-0001".
     */
    private static boolean coincide(Pedido p, String q) {
        String texto = q.toLowerCase();
        if (p.getClienteNombre().toLowerCase().contains(texto)
                || p.getDescripcion().toLowerCase().contains(texto)) {
            return true;
        }
        String digitos = soloDigitos(q);
        return !digitos.isEmpty() && soloDigitos(p.getClienteTelefono()).contains(digitos);
    }

    private static String soloDigitos(String valor) {
        return valor == null ? "" : valor.replaceAll("\\D", "");
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

        if (dto.fechaEntrega() != null && dto.fechaEntrega().isBefore(LocalDateTime.now())) {
            throw new PedidoInvalidoException("La fecha de entrega no puede ser anterior al momento actual.");
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
            MetodoPago metodo = metodoDe(dto.metodoPagoSeniaId());
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
        MetodoPago metodo = metodoDe(dto.metodoPagoId());
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
        if (pedido.getEstado() == EstadoPedido.CANCELADO) {
            throw new PedidoInvalidoException("El pedido ya está cancelado.");
        }

        pedido.setEstado(EstadoPedido.CANCELADO);
        Pedido guardado = pedidoRepository.save(pedido);
        log.info("[PEDIDO] Cancelado pedido ID {}", id);
        return toResponseDTO(guardado);
    }

    /** Método activo indicado; sin indicar, Efectivo. */
    private MetodoPago metodoDe(Long id) {
        return id == null ? metodoPagoService.efectivo() : metodoPagoService.paraCobrar(id);
    }

    public PedidoResponseDTO toResponseDTO(Pedido p) {
        List<PedidoAbonoDTO> abonosDTO = p.getAbonos().stream()
                .map(a -> new PedidoAbonoDTO(
                        a.getId(),
                        a.getMonto(),
                        a.getMetodoPago().getNombre(),
                        a.getNota(),
                        a.getCreatedAt(),
                        a.getMetodoPago().getId()
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
