package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.FaltanComponentesException;
import com.sgiu_group.sgiu.exceptions.ProductoInvalidoException;
import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.FaltanteDTO;
import com.sgiu_group.sgiu.models.dtos.ProduccionResponseDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MovimientoStock;
import com.sgiu_group.sgiu.models.entities.PaqueteArmado;
import com.sgiu_group.sgiu.models.entities.Produccion;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.TipoMovimientoStock;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.PaqueteArmadoRepository;
import com.sgiu_group.sgiu.repositories.ProduccionRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Producción por tanda: cargar stock de un elaborado o un paquete descuenta
 * sus componentes según la receta (o el armado) y el rinde:
 * factor = cantidad producida / rinde; cada componente consume su cantidad
 * base × factor. Las preparaciones base (ganache) no tienen stock: se
 * descuentan directamente sus ingredientes, en varios niveles.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ProduccionService {

    private static final MathContext PRECISION = new MathContext(20, RoundingMode.HALF_UP);

    private final EspProductoRepository productoRepository;
    private final RecetaRepository recetaRepository;
    private final PaqueteArmadoRepository armadoRepository;
    private final ArticuloStockRepository stockRepository;
    private final ProduccionRepository produccionRepository;
    private final StockService stockService;

    /** Lo que consume un artículo: el componente y su cantidad en unidad base. */
    public record Consumo(EspProducto articulo, BigDecimal cantidadBase) {}

    /**
     * Produce [cantidad] unidades. Si algún componente quedaría en negativo y
     * no se confirmó, no aplica nada y lanza la lista de faltantes; si se
     * confirmó, produce igual (el stock queda negativo y la producción queda
     * marcada). Todo en una transacción.
     */
    @Transactional
    public ProduccionResponseDTO producir(String codigo, int cantidad, boolean confirmarFaltantes, String motivo) {
        EspProducto producto = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Producto no encontrado: " + codigo));
        validarQueSeProduce(producto);

        Map<Long, Consumo> consumos = consumoPara(producto, BigDecimal.valueOf(cantidad));
        List<FaltanteDTO> faltantes = faltantes(consumos);
        if (!faltantes.isEmpty() && !confirmarFaltantes) {
            throw new FaltanComponentesException("No alcanzan los componentes para producir " + cantidad + " "
                    + producto.getNombre() + ". " + String.join(" ", faltantes.stream().map(FaltanteDTO::mensaje).toList())
                    + " Confirme para producir igual (el stock quedará en negativo).", faltantes);
        }

        Produccion produccion = new Produccion();
        produccion.setArticulo(producto);
        produccion.setCantidad(BigDecimal.valueOf(cantidad));
        // Costo unitario congelado al producir.
        produccion.setCostoUnitario(producto.getPrecioCosto() != null ? producto.getPrecioCosto() : BigDecimal.ZERO);
        produccion.setConFaltantes(!faltantes.isEmpty());
        produccion.setFaltantes(faltantes.isEmpty() ? null
                : recortar(String.join(" ", faltantes.stream().map(FaltanteDTO::mensaje).toList()), 2000));
        produccion.setMotivo(motivo != null && !motivo.isBlank() ? recortar(motivo.trim(), 255) : null);
        produccion.setFecha(LocalDateTime.now());
        produccion.setUsuario(StockService.usuarioActual());
        produccion = produccionRepository.save(produccion);

        String detalle = "Producción de " + cantidad + " " + producto.getNombre() + " (" + producto.getCodigo() + ")";
        MovimientoStock entrada = stockService.mover(producto, TipoMovimientoStock.PRODUCCION,
                BigDecimal.valueOf(cantidad), produccion.getMotivo() != null ? produccion.getMotivo() : detalle,
                produccion, null);
        List<ProduccionResponseDTO.Consumo> consumidos = new ArrayList<>();
        for (Consumo c : consumos.values()) {
            MovimientoStock m = stockService.mover(c.articulo(), TipoMovimientoStock.CONSUMO_PRODUCCION,
                    c.cantidadBase().negate(), detalle, produccion, null);
            consumidos.add(new ProduccionResponseDTO.Consumo(
                    c.articulo().getCodigo(),
                    c.articulo().getNombre(),
                    m.getCantidad(),
                    StockService.texto(c.articulo(), m.getCantidad(), true),
                    m.getStockResultante(),
                    StockService.texto(c.articulo(), m.getStockResultante(), false),
                    m.getStockResultante().signum() < 0));
        }
        log.info("[PRODUCCION] {}{}", detalle, faltantes.isEmpty() ? "" : " (con faltantes)");
        return new ProduccionResponseDTO(produccion.getId(), producto.getCodigo(), producto.getNombre(),
                produccion.getCantidad(), produccion.getCostoUnitario(), produccion.isConFaltantes(), faltantes,
                consumidos, producto.unidadesDeVentaEn(entrada.getStockResultante()));
    }

    /**
     * Cuántas unidades se pueden producir con el stock actual de los
     * componentes ("puedo producir hasta N"); null si el artículo no se
     * produce o no tiene receta/armado.
     */
    @Transactional(readOnly = true)
    public Long puedeProducir(EspProducto producto) {
        if (!seProduce(producto)) {
            return null;
        }
        Map<Long, Consumo> porUnidad;
        try {
            porUnidad = consumoPara(producto, BigDecimal.ONE);
        } catch (RecetaInvalidaException | ProductoInvalidoException e) {
            return null;
        }
        if (porUnidad.isEmpty()) {
            return null;
        }
        long maximo = Long.MAX_VALUE;
        for (Consumo c : porUnidad.values()) {
            if (c.cantidadBase().signum() <= 0) {
                continue;
            }
            BigDecimal hay = stockDe(c.articulo());
            long alcanza = hay.signum() <= 0 ? 0
                    : hay.divide(c.cantidadBase(), 0, RoundingMode.FLOOR).longValue();
            maximo = Math.min(maximo, alcanza);
        }
        return maximo == Long.MAX_VALUE ? null : maximo;
    }

    /** Lo que consume producir [cantidad] unidades, por componente (redondeado a 3 decimales). */
    public Map<Long, Consumo> consumoPara(EspProducto producto, BigDecimal cantidad) {
        Map<Long, BigDecimal> cantidades = new LinkedHashMap<>();
        Map<Long, EspProducto> articulos = new LinkedHashMap<>();
        if (producto.getTipo() == TipoArticulo.PAQUETE) {
            List<PaqueteArmado> armado = armadoRepository.findByPaqueteOrderById(producto);
            if (armado.isEmpty()) {
                throw new ProductoInvalidoException(producto.getNombre() + " no tiene armado.");
            }
            for (PaqueteArmado a : armado) {
                sumar(a.getArticulo(), a.getCantidadBase().multiply(cantidad), cantidades, articulos);
            }
        } else {
            Receta receta = recetaActiva(producto);
            agregarReceta(receta, cantidad.divide(rinde(receta), PRECISION), cantidades, articulos, new HashSet<>());
        }
        Map<Long, Consumo> consumos = new LinkedHashMap<>();
        cantidades.forEach((id, c) ->
                consumos.put(id, new Consumo(articulos.get(id), c.setScale(3, RoundingMode.HALF_UP))));
        return consumos;
    }

    /**
     * Suma los ingredientes de una receta multiplicados por [factor]. Una
     * preparación base no tiene stock: se baja a sus propios ingredientes
     * (factor = cantidad usada / rinde en unidad base).
     */
    private void agregarReceta(Receta receta, BigDecimal factor, Map<Long, BigDecimal> cantidades,
                               Map<Long, EspProducto> articulos, Set<Long> enCurso) {
        if (!enCurso.add(receta.getProducto().getId())) {
            throw new RecetaInvalidaException("Hay un ciclo entre recetas en " + receta.getProducto().getNombre() + ".");
        }
        for (RecetaDetalle d : receta.getDetalles()) {
            EspProducto componente = d.getArticulo();
            BigDecimal usado = d.getCantidadBase().multiply(factor, PRECISION);
            if (componente.esPreparacionBase()) {
                Receta sub = recetaActiva(componente);
                BigDecimal rindeBase = sub.getRindeUnidadMedida() != null
                        ? sub.getRindeUnidadMedida().aBase(rinde(sub)) : rinde(sub);
                agregarReceta(sub, usado.divide(rindeBase, PRECISION), cantidades, articulos, enCurso);
            } else {
                sumar(componente, usado, cantidades, articulos);
            }
        }
        enCurso.remove(receta.getProducto().getId());
    }

    private static void sumar(EspProducto a, BigDecimal cantidad, Map<Long, BigDecimal> cantidades,
                              Map<Long, EspProducto> articulos) {
        articulos.putIfAbsent(a.getId(), a);
        cantidades.merge(a.getId(), cantidad, BigDecimal::add);
    }

    private List<FaltanteDTO> faltantes(Map<Long, Consumo> consumos) {
        List<FaltanteDTO> faltantes = new ArrayList<>();
        for (Consumo c : consumos.values()) {
            BigDecimal hay = stockDe(c.articulo());
            if (hay.compareTo(c.cantidadBase()) < 0) {
                BigDecimal falta = c.cantidadBase().subtract(hay.max(BigDecimal.ZERO));
                EspProducto a = c.articulo();
                faltantes.add(new FaltanteDTO(a.getCodigo(), a.getNombre(), hay, c.cantidadBase(), falta,
                        "Faltan " + StockService.texto(a, falta, false) + " de " + a.getNombre() + ": hay "
                                + StockService.texto(a, hay, false) + ", se necesitan "
                                + StockService.texto(a, c.cantidadBase(), false) + "."));
            }
        }
        return faltantes;
    }

    private BigDecimal stockDe(EspProducto a) {
        return stockRepository.findByEspProducto(a).map(ArticuloStock::getCantidad).orElse(BigDecimal.ZERO);
    }

    private Receta recetaActiva(EspProducto producto) {
        return recetaRepository.findByProducto_IdAndActivoTrue(producto.getId())
                .orElseThrow(() -> new RecetaInvalidaException(producto.getNombre()
                        + " no tiene receta: cárguela en Recetas y paquetes para poder producirlo."));
    }

    private static boolean seProduce(EspProducto p) {
        return p.getTipo() == TipoArticulo.PAQUETE || p.getTipo() == TipoArticulo.ELABORADO && p.isVendible();
    }

    private static void validarQueSeProduce(EspProducto p) {
        if (p.esPreparacionBase()) {
            throw new ProductoInvalidoException(p.getNombre() + " es una preparación base: no tiene stock. Sus "
                    + "ingredientes se descuentan al producir lo que la usa.");
        }
        if (!seProduce(p)) {
            throw new ProductoInvalidoException("Solo se producen elaborados y paquetes: " + p.getNombre()
                    + " se carga como compra o ajuste.");
        }
    }

    private static BigDecimal rinde(Receta r) {
        return r.getRinde() != null && r.getRinde().signum() > 0 ? r.getRinde() : BigDecimal.ONE;
    }

    private static String recortar(String s, int max) {
        return s.length() > max ? s.substring(0, max) : s;
    }
}
