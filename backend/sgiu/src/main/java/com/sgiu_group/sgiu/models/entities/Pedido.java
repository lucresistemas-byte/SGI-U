package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pedidos")
@Getter
@Setter
@NoArgsConstructor
public class Pedido extends BaseEntity {

    @Column(name = "cliente_nombre", nullable = false, length = 100)
    private String clienteNombre;

    @Column(name = "cliente_telefono", nullable = false, length = 50)
    private String clienteTelefono;

    @Column(nullable = false, length = 255)
    private String descripcion;

    @Column(name = "monto_total", nullable = false, precision = 10, scale = 2)
    private BigDecimal montoTotal;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal senia;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal saldo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoPedido estado = EstadoPedido.PENDIENTE;

    @Column(name = "fecha_entrega")
    private LocalDateTime fechaEntrega;

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<PedidoAbono> abonos = new ArrayList<>();

    @Column(nullable = false)
    private boolean activo = true;

    public Pedido(String clienteNombre, String clienteTelefono, String descripcion,
                  BigDecimal montoTotal, BigDecimal senia, LocalDateTime fechaEntrega) {
        this.clienteNombre = clienteNombre;
        this.clienteTelefono = clienteTelefono;
        this.descripcion = descripcion;
        this.montoTotal = montoTotal != null ? montoTotal : BigDecimal.ZERO;
        this.senia = senia != null ? senia : BigDecimal.ZERO;
        this.saldo = this.montoTotal.subtract(this.senia);
        this.fechaEntrega = fechaEntrega;
        this.estado = this.saldo.compareTo(BigDecimal.ZERO) <= 0 ? EstadoPedido.PAGADO : EstadoPedido.PENDIENTE;
        this.activo = true;
    }

    public void addAbono(PedidoAbono abono) {
        abonos.add(abono);
        abono.setPedido(this);
    }
}
