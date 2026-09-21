package com.sgiu_group.sgiu.models.entities;

import com.sgiu_group.sgiu.models.base.BaseEntity;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "pedidos_abonos")
@Getter
@Setter
@NoArgsConstructor
public class PedidoAbono extends BaseEntity {

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "pedido_id", nullable = false, foreignKey = @ForeignKey(name = "fk_pedido_abono_pedido"))
    @JsonIgnore
    private Pedido pedido;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @Column(name = "metodo_pago", length = 50)
    private String metodoPago = "EFECTIVO";

    @Column(length = 255)
    private String nota;

    public PedidoAbono(Pedido pedido, BigDecimal monto, String metodoPago, String nota) {
        this.pedido = pedido;
        this.monto = monto;
        this.metodoPago = metodoPago != null ? metodoPago : "EFECTIVO";
        this.nota = nota;
    }
}
