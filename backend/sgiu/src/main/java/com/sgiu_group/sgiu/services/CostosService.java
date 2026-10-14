package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.PrecioInvalidoException;
import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.models.dtos.CambioPrecioDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.HistorialPrecio;
import com.sgiu_group.sgiu.models.entities.ModoPrecio;
import com.sgiu_group.sgiu.models.entities.PaqueteArmado;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.RecetaDetalle;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.HistorialPrecioRepository;
import com.sgiu_group.sgiu.repositories.PaqueteArmadoRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Único lugar donde se calculan costos y precios:
 * <ul>
 *   <li>costo por unidad base (materia prima, insumo, reventa + materia prima
 *       desde su presentación de compra; preparación base desde su receta),</li>
 *   <li>costo de receta y costo unitario (= costo de receta / rinde),</li>
 *   <li>costo de paquete (suma de su armado),</li>
 *   <li>precio de venta según el modo (MARGEN, MANUAL, COSTO_MAS_FIJO),
 *       siempre redondeado hacia arriba a $100,</li>
 * </ul>
 * y la propagación: cuando cambia un artículo, se recalculan todos los que
 * dependen de él, en orden topológico (chocolate → ganache → torta), una vez
 * cada uno y en la misma transacción, dejando historial de cada cambio.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CostosService {

    private static final BigDecimal CIEN = new BigDecimal("100");

    private final EspProductoRepository productoRepository;
    private final RecetaRepository recetaRepository;
    private final PaqueteArmadoRepository armadoRepository;
    private final HistorialPrecioRepository historialRepository;

    // ------------------------------------------------------------------
    // Cálculos
    // ------------------------------------------------------------------

    /** Precio de venta: hacia arriba al próximo múltiplo de $100 ($3.601 → $3.700). */
    public static BigDecimal redondearA100(BigDecimal precio) {
        if (precio == null || precio.signum() <= 0) {
            return BigDecimal.ZERO.setScale(2);
        }
        return precio.divide(CIEN, 0, RoundingMode.CEILING).multiply(CIEN).setScale(2, RoundingMode.UNNECESSARY);
    }

    /** Ganancia por unidad en pesos: precio − costo unitario. */
    public static BigDecimal ganancia(BigDecimal precio, BigDecimal costo) {
        return nz(precio).subtract(nz(costo)).setScale(2, RoundingMode.HALF_UP);
    }

    /** Costo por unidad base desde la presentación de compra: bolsa de 25 kg a $30.000 → $1,2000 el gramo. */
    public BigDecimal costoUnidadBaseDesdePresentacion(EspProducto a) {
        BigDecimal base = a.presentacionEnBase();
        if (base == null || base.signum() <= 0 || a.getPresentacionPrecio() == null) {
            return nz(a.getCostoUnidadBase());
        }
        return a.getPresentacionPrecio().divide(base, 4, RoundingMode.HALF_UP);
    }

    /** Costo de una unidad de la familia del artículo (p. ej. el kilo), 4 decimales. */
    public BigDecimal costoPor(EspProducto a, UnidadMedida unidad) {
        return nz(a.getCostoUnidadBase()).multiply(unidad.getFactor()).setScale(4, RoundingMode.HALF_UP);
    }

    /** Costo de una fila de receta (sin redondear): cantidad en unidad base × costo por unidad base. */
    public BigDecimal costoFila(RecetaDetalle d) {
        return nz(d.getArticulo().getCostoUnidadBase()).multiply(nz(d.getCantidadBase()));
    }

    public BigDecimal subtotalFila(RecetaDetalle d) {
        return costoFila(d).setScale(2, RoundingMode.HALF_UP);
    }

    /** Costo total de la receta: filas + costos adicionales, 2 decimales. */
    public BigDecimal costoReceta(Receta r) {
        BigDecimal total = nz(r.getCostosAdicionales());
        for (RecetaDetalle d : r.getDetalles()) {
            total = total.add(costoFila(d));
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    /** Costo de una unidad rendida (porción, alfajor, gramo de ganache): costo de receta / rinde. */
    public BigDecimal costoUnitario(Receta r) {
        return costoReceta(r).divide(rinde(r), 2, RoundingMode.HALF_UP);
    }

    /** Preparación base: costo por unidad base del rinde (ganache que rinde 800 g → $ por gramo). */
    public BigDecimal costoUnidadBasePreparacion(Receta r) {
        BigDecimal rindeBase = r.getRindeUnidadMedida() != null
                ? r.getRindeUnidadMedida().aBase(rinde(r)) : rinde(r);
        return costoReceta(r).divide(rindeBase, 4, RoundingMode.HALF_UP);
    }

    public BigDecimal costoFilaArmado(PaqueteArmado a) {
        return nz(a.getArticulo().getCostoUnidadBase()).multiply(nz(a.getCantidadBase()));
    }

    /** Costo del armado de un paquete: suma de sus insumos, 2 decimales. */
    public BigDecimal costoArmado(List<PaqueteArmado> armado) {
        BigDecimal total = BigDecimal.ZERO;
        for (PaqueteArmado a : armado) {
            total = total.add(costoFilaArmado(a));
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    /** Precio mínimo que deja el % de ganancia: costo × (1 + %), redondeado a $100. */
    public BigDecimal precioMinimo(BigDecimal costoUnitario, BigDecimal porcentaje) {
        BigDecimal factor = BigDecimal.ONE.add(nz(porcentaje).divide(CIEN, 6, RoundingMode.HALF_UP));
        return redondearA100(nz(costoUnitario).multiply(factor));
    }

    /**
     * % de ganancia que deja un precio (redondeado a $100) sobre un costo;
     * 0 sin costo. Se usa como mínimo de un precio a mano cargado sin %.
     */
    public BigDecimal porcentajeQueDeja(BigDecimal precio, BigDecimal costo) {
        if (costo == null || costo.signum() <= 0) {
            return BigDecimal.ZERO;
        }
        return redondearA100(precio).subtract(costo).multiply(CIEN).divide(costo, 2, RoundingMode.FLOOR);
    }

    /** Precio de venta según el modo del artículo, con su costo unitario ya calculado. */
    public BigDecimal precioSegunModo(EspProducto a) {
        BigDecimal minimo = precioMinimo(a.getPrecioCosto(), a.getPorcentajeGanancia());
        return switch (a.getModoPrecio()) {
            case MARGEN -> minimo;
            // El precio de Sandra se conserva mientras deje el %; si no, sube al mínimo.
            case MANUAL -> redondearA100(a.getPrecioUnitario()).max(minimo);
            case COSTO_MAS_FIJO -> redondearA100(nz(a.getPrecioCosto()).add(nz(a.getMontoFijo())));
        };
    }

    /**
     * Fija un precio a mano (se redondea a $100). Tiene que dejar al menos el
     * % de ganancia del artículo: si no, se rechaza indicando el mínimo. El
     * costo unitario tiene que estar calculado (ver {@link #recalcular}).
     */
    public void aplicarPrecioManual(EspProducto a, BigDecimal precio) {
        BigDecimal redondeado = redondearA100(precio);
        BigDecimal minimo = precioMinimo(a.getPrecioCosto(), a.getPorcentajeGanancia());
        if (redondeado.signum() <= 0) {
            throw new PrecioInvalidoException("El precio debe ser un valor mayor a $0.");
        }
        if (redondeado.compareTo(minimo) < 0) {
            throw new PrecioInvalidoException("El precio $" + redondeado.toPlainString() + " deja menos del "
                    + nz(a.getPorcentajeGanancia()).stripTrailingZeros().toPlainString() + " % de ganancia de "
                    + a.getNombre() + ": el mínimo es $" + minimo.toPlainString() + ".");
        }
        a.setModoPrecio(ModoPrecio.MANUAL);
        a.setPrecioUnitario(redondeado);
    }

    /**
     * Recalcula costo y precio del artículo desde su definición (presentación,
     * receta activa o armado), sin tocar los que dependen de él.
     */
    public void recalcular(EspProducto a) {
        switch (a.getTipo()) {
            case MATERIA_PRIMA, INSUMO -> a.setCostoUnidadBase(costoUnidadBaseDesdePresentacion(a));
            case REVENTA_MATERIA_PRIMA -> {
                a.setCostoUnidadBase(costoUnidadBaseDesdePresentacion(a));
                a.setPrecioCosto(nz(a.getCostoUnidadBase()).multiply(nz(a.getVentaUnidadContenido()))
                        .setScale(2, RoundingMode.HALF_UP));
                a.setPrecioUnitario(precioSegunModo(a));
            }
            case ELABORADO -> {
                Optional<Receta> receta = a.getId() == null
                        ? Optional.empty() : recetaRepository.findByProducto_IdAndActivoTrue(a.getId());
                if (a.esPreparacionBase()) {
                    // No se vende: su costo por unidad base es el que usan las recetas.
                    receta.ifPresent(r -> {
                        a.setCostoUnidadBase(costoUnidadBasePreparacion(r));
                        a.setPrecioCosto(costoPor(a, a.getUnidadMedida()).setScale(2, RoundingMode.HALF_UP));
                    });
                    a.setPrecioUnitario(BigDecimal.ZERO.setScale(2));
                } else {
                    receta.ifPresent(r -> a.setPrecioCosto(costoUnitario(r)));
                    a.setPrecioUnitario(precioSegunModo(a));
                }
            }
            // El costo de la reventa lo carga Sandra.
            case REVENTA -> a.setPrecioUnitario(precioSegunModo(a));
            case PAQUETE -> {
                List<PaqueteArmado> armado = a.getId() == null ? List.of() : armadoRepository.findByPaqueteOrderById(a);
                a.setPrecioCosto(costoArmado(armado));
                a.setModoPrecio(ModoPrecio.COSTO_MAS_FIJO);
                a.setPrecioUnitario(precioSegunModo(a));
            }
        }
    }

    // ------------------------------------------------------------------
    // Propagación
    // ------------------------------------------------------------------

    /** Costo y precio de un artículo antes de un cambio (para el historial y el resumen). */
    public record Foto(BigDecimal costo, BigDecimal precio) {}

    public Foto foto(EspProducto a) {
        return new Foto(costoParaHistorial(a), a.getPrecioUnitario());
    }

    /**
     * Recalcula [origen] y, en orden topológico, todo lo que depende de él
     * (recetas activas que lo usan y paquetes que lo arman, en varios
     * niveles). Cada artículo se recalcula una vez. Deja historial de cada
     * costo o precio que cambió y devuelve los precios de venta que cambiaron.
     * Si los datos tienen un ciclo, lanza una excepción y la transacción no
     * cambia nada.
     *
     * @param antes foto del origen antes del cambio (null en un alta: no hay historial del origen).
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public List<CambioPrecioDTO> propagar(EspProducto origen, Foto antes, String causa) {
        LocalDateTime ahora = LocalDateTime.now();
        String usuario = usuarioActual();
        List<CambioPrecioDTO> cambios = new ArrayList<>();
        // Primero el orden: si hay un ciclo, se corta antes de cambiar nada.
        List<EspProducto> dependientes = origen.getId() == null ? List.of() : dependientesEnOrden(origen);

        recalcular(origen);
        productoRepository.save(origen);
        if (antes != null) {
            registrar(origen, antes, causa, origen, ahora, usuario, cambios);
        }

        for (EspProducto dependiente : dependientes) {
            Foto fotoDependiente = foto(dependiente);
            recalcular(dependiente);
            productoRepository.save(dependiente);
            registrar(dependiente, fotoDependiente, causa, origen, ahora, usuario, cambios);
        }
        if (!cambios.isEmpty()) {
            log.info("[PRECIOS] {}: se actualizaron {} precios", causa, cambios.size());
        }
        return cambios;
    }

    /**
     * Todo lo que depende de [origen], en orden topológico: cada artículo
     * después de todos los que usa. DFS con marcas (en curso / terminado): si
     * se vuelve a un artículo en curso, hay un ciclo.
     */
    List<EspProducto> dependientesEnOrden(EspProducto origen) {
        Map<Long, EspProducto> porId = new HashMap<>();
        Map<Long, Boolean> terminado = new HashMap<>();
        List<EspProducto> postorden = new ArrayList<>();
        dfs(origen, porId, terminado, new LinkedHashSet<>(), postorden);
        List<EspProducto> orden = new ArrayList<>();
        for (int i = postorden.size() - 1; i >= 0; i--) {
            if (postorden.get(i) != origen) {
                orden.add(postorden.get(i));
            }
        }
        return orden;
    }

    private void dfs(EspProducto actual, Map<Long, EspProducto> porId, Map<Long, Boolean> terminado,
                     LinkedHashSet<Long> enCurso, List<EspProducto> postorden) {
        porId.put(actual.getId(), actual);
        enCurso.add(actual.getId());
        for (EspProducto siguiente : dependientesDirectos(actual)) {
            if (enCurso.contains(siguiente.getId())) {
                throw new RecetaInvalidaException("Hay un ciclo entre recetas: " + describirCiclo(enCurso, siguiente, porId)
                        + ". No se cambió nada: corrija una de esas recetas.");
            }
            if (!terminado.containsKey(siguiente.getId())) {
                dfs(siguiente, porId, terminado, enCurso, postorden);
            }
        }
        enCurso.remove(actual.getId());
        terminado.put(actual.getId(), true);
        postorden.add(actual);
    }

    /** Elaborados cuyas recetas activas usan el artículo y paquetes que lo arman. */
    private List<EspProducto> dependientesDirectos(EspProducto a) {
        Map<Long, EspProducto> directos = new LinkedHashMap<>();
        for (Receta r : recetaRepository.findRecetasByArticuloId(a.getId())) {
            directos.putIfAbsent(r.getProducto().getId(), r.getProducto());
        }
        for (EspProducto paquete : armadoRepository.findPaquetesQueUsan(a.getId())) {
            directos.putIfAbsent(paquete.getId(), paquete);
        }
        return new ArrayList<>(directos.values());
    }

    private static String describirCiclo(LinkedHashSet<Long> enCurso, EspProducto repetido, Map<Long, EspProducto> porId) {
        List<String> nombres = new ArrayList<>();
        boolean dentro = false;
        for (Long id : enCurso) {
            dentro |= id.equals(repetido.getId());
            if (dentro) {
                nombres.add(porId.get(id).getNombre());
            }
        }
        nombres.add(repetido.getNombre());
        return String.join(" → ", nombres);
    }

    private void registrar(EspProducto a, Foto antes, String causa, EspProducto origen, LocalDateTime fecha,
                           String usuario, List<CambioPrecioDTO> cambios) {
        BigDecimal costo = costoParaHistorial(a);
        boolean cambioCosto = distintos(antes.costo(), costo);
        boolean cambioPrecio = distintos(antes.precio(), a.getPrecioUnitario());
        if (!cambioCosto && !cambioPrecio) {
            return;
        }
        HistorialPrecio h = new HistorialPrecio();
        h.setArticulo(a);
        h.setCostoAnterior(antes.costo());
        h.setCostoNuevo(costo);
        h.setPrecioAnterior(antes.precio());
        h.setPrecioNuevo(a.getPrecioUnitario());
        h.setModoPrecio(a.getModoPrecio());
        h.setCausa(causa.length() > 255 ? causa.substring(0, 255) : causa);
        h.setCausaArticulo(origen);
        h.setFecha(fecha);
        h.setUsuario(usuario);
        historialRepository.save(h);
        if (cambioPrecio && a.getTipo().seVende()) {
            cambios.add(new CambioPrecioDTO(a.getCodigo(), a.getNombre(), antes.precio(), a.getPrecioUnitario(),
                    a.getPrecioCosto(), ganancia(a.getPrecioUnitario(), a.getPrecioCosto())));
        }
    }

    /** Lo que cuesta el artículo para el historial: por unidad base en materia prima y preparaciones base. */
    private static BigDecimal costoParaHistorial(EspProducto a) {
        boolean porUnidadBase = a.getTipo() == TipoArticulo.MATERIA_PRIMA || a.getTipo() == TipoArticulo.INSUMO
                || a.esPreparacionBase();
        return porUnidadBase ? a.getCostoUnidadBase() : a.getPrecioCosto();
    }

    private static boolean distintos(BigDecimal x, BigDecimal y) {
        if (x == null || y == null) {
            return x != y && nz(x).compareTo(nz(y)) != 0;
        }
        return x.compareTo(y) != 0;
    }

    private static String usuarioActual() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.isAuthenticated() ? auth.getName() : "sistema";
    }

    private static BigDecimal rinde(Receta r) {
        return r.getRinde() != null && r.getRinde().signum() > 0 ? r.getRinde() : BigDecimal.ONE;
    }

    private static BigDecimal nz(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }

    /** Ids de todos los artículos que usa la receta activa de [producto], en varios niveles (para detectar ciclos al guardar). */
    public Set<Long> componentesTransitivos(Long productoId) {
        Set<Long> vistos = new LinkedHashSet<>();
        juntarComponentes(productoId, vistos);
        return vistos;
    }

    private void juntarComponentes(Long productoId, Set<Long> vistos) {
        recetaRepository.findByProducto_IdAndActivoTrue(productoId).ifPresent(r -> {
            for (RecetaDetalle d : r.getDetalles()) {
                if (vistos.add(d.getArticulo().getId())) {
                    juntarComponentes(d.getArticulo().getId(), vistos);
                }
            }
        });
    }
}
