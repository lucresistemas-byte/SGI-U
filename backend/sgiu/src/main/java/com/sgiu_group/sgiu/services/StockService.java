package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.FechasInvalidasException;
import com.sgiu_group.sgiu.exceptions.ProductoInvalidoException;
import com.sgiu_group.sgiu.models.dtos.MovimientoStockDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.FamiliaUnidad;
import com.sgiu_group.sgiu.models.entities.MovimientoStock;
import com.sgiu_group.sgiu.models.entities.Produccion;
import com.sgiu_group.sgiu.models.entities.TipoMovimientoStock;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.models.entities.Venta;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.MovimientoStockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Único lugar que cambia el stock: cada cambio suma una cantidad firmada (en
 * unidad base) al stock del artículo y deja un movimiento en el historial con
 * el stock resultante. El stock puede quedar negativo (producción confirmada
 * con faltantes).
 */
@Service
@RequiredArgsConstructor
public class StockService {

    private final ArticuloStockRepository stockRepository;
    private final MovimientoStockRepository movimientoRepository;

    /**
     * Aplica un movimiento de stock. [cantidadBase] con signo: + entra, − sale.
     * Se llama dentro de la transacción del cambio (venta, producción, ajuste).
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public MovimientoStock mover(EspProducto articulo, TipoMovimientoStock tipo, BigDecimal cantidadBase,
                                 String motivo, Produccion produccion, Venta venta) {
        ArticuloStock stock = stockRepository.findByEspProducto(articulo)
                .orElseGet(() -> new ArticuloStock(articulo, BigDecimal.ZERO));
        return mover(stock, tipo, cantidadBase, motivo, produccion, venta);
    }

    /** Igual que {@link #mover(EspProducto, TipoMovimientoStock, BigDecimal, String, Produccion, Venta)}, con la fila de stock ya leída. */
    @Transactional(propagation = Propagation.MANDATORY)
    public MovimientoStock mover(ArticuloStock stock, TipoMovimientoStock tipo, BigDecimal cantidadBase,
                                 String motivo, Produccion produccion, Venta venta) {
        EspProducto articulo = stock.getEspProducto();
        BigDecimal cantidad = cantidadBase.setScale(3, RoundingMode.HALF_UP);
        stock.setCantidad(stock.getCantidad().add(cantidad));
        stockRepository.save(stock);

        MovimientoStock m = new MovimientoStock();
        m.setArticulo(articulo);
        m.setTipo(tipo);
        m.setCantidad(cantidad);
        m.setStockResultante(stock.getCantidad());
        m.setMotivo(motivo != null && motivo.length() > 255 ? motivo.substring(0, 255) : motivo);
        m.setProduccion(produccion);
        m.setVenta(venta);
        m.setFecha(LocalDateTime.now());
        m.setUsuario(usuarioActual());
        return movimientoRepository.save(m);
    }

    /**
     * Tipo de un ajuste manual: COMPRA suma, MERMA resta, AJUSTE cualquiera.
     * Sin tipo: COMPRA si suma y AJUSTE si resta.
     */
    public static TipoMovimientoStock tipoDeAjuste(String tipo, int signo) {
        if (tipo == null || tipo.isBlank()) {
            return signo > 0 ? TipoMovimientoStock.COMPRA : TipoMovimientoStock.AJUSTE;
        }
        TipoMovimientoStock t;
        try {
            t = TipoMovimientoStock.valueOf(tipo.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ProductoInvalidoException("Tipo de movimiento no válido: " + tipo + ". Use COMPRA, AJUSTE o MERMA.");
        }
        switch (t) {
            case COMPRA -> {
                if (signo < 0) {
                    throw new ProductoInvalidoException("Una compra suma stock: la cantidad tiene que ser positiva.");
                }
            }
            case MERMA -> {
                if (signo > 0) {
                    throw new ProductoInvalidoException("Una merma resta stock: la cantidad tiene que ser negativa.");
                }
            }
            case AJUSTE -> { }
            default -> throw new ProductoInvalidoException(
                    "Los movimientos de " + t.getDescripcion().toLowerCase() + " los registra el sistema.");
        }
        return t;
    }

    /** Historial de stock de un artículo; sin fechas, los últimos 30 días. */
    @Transactional(readOnly = true)
    public List<MovimientoStockDTO> historial(String codigo, LocalDate desde, LocalDate hasta, String tipo) {
        LocalDate fin = hasta != null ? hasta : LocalDate.now();
        LocalDate inicio = desde != null ? desde : fin.minusDays(30);
        if (inicio.isAfter(fin)) {
            throw new FechasInvalidasException("La fecha desde no puede ser posterior a la fecha hasta.");
        }
        TipoMovimientoStock filtro = null;
        if (tipo != null && !tipo.isBlank()) {
            try {
                filtro = TipoMovimientoStock.valueOf(tipo.trim().toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new ProductoInvalidoException("Tipo de movimiento no válido: " + tipo);
            }
        }
        return movimientoRepository.buscar(codigo, inicio.atStartOfDay(), fin.plusDays(1).atStartOfDay(), filtro)
                .stream()
                .map(m -> new MovimientoStockDTO(
                        m.getId(),
                        m.getFecha(),
                        m.getArticulo().getCodigo(),
                        m.getArticulo().getNombre(),
                        m.getTipo().name(),
                        m.getTipo().getDescripcion(),
                        m.getCantidad(),
                        texto(m.getArticulo(), m.getCantidad(), true),
                        m.getStockResultante(),
                        texto(m.getArticulo(), m.getStockResultante(), false),
                        m.getMotivo(),
                        m.getProduccion() != null ? m.getProduccion().getId() : null,
                        m.getVenta() != null ? m.getVenta().getId() : null,
                        m.getUsuario()))
                .toList();
    }

    /**
     * Cantidad en unidad base mostrada amigable: "−120 g", "2,5 kg", "+3 u".
     * Los artículos sin familia (elaborados, reventa, paquetes) van en unidades.
     */
    public static String texto(EspProducto a, BigDecimal base, boolean conSigno) {
        String t;
        FamiliaUnidad familia = a.getFamilia();
        if (familia == null || familia == FamiliaUnidad.UNIDAD) {
            t = base.stripTrailingZeros().toPlainString().replace('.', ',') + " u";
        } else {
            List<UnidadMedida> unidades = UnidadMedida.de(familia);
            UnidadMedida grande = unidades.get(unidades.size() - 1);
            UnidadMedida unidad = base.abs().compareTo(grande.getFactor()) >= 0 ? grande : familia.getUnidadBase();
            t = unidad.texto(base);
        }
        t = t.replace('-', '−');
        return conSigno && base.signum() > 0 ? "+" + t : t;
    }

    static String usuarioActual() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.isAuthenticated() ? auth.getName() : "sistema";
    }
}
