package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.AjusteStockInsumoDTO;
import com.sgiu_group.sgiu.models.dtos.InsumoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.InsumoResponseDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.FamiliaUnidad;
import com.sgiu_group.sgiu.models.entities.MateriaPrima;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MateriaPrimaService {

    private final MateriaPrimaRepository materiaPrimaRepository;
    private final RecetaRepository recetaRepository;
    private final EspProductoRepository espProductoRepository;
    private final CodigoService codigoService;

    @Transactional(readOnly = true)
    public List<InsumoResponseDTO> listarTodos(boolean incluirInactivos) {
        List<MateriaPrima> insumos = incluirInactivos
                ? materiaPrimaRepository.findAll()
                : materiaPrimaRepository.findByActivoTrue();
        return insumos.stream()
                .map(this::toResponseDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public InsumoResponseDTO obtenerPorId(Long id) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));
        return toResponseDTO(mp);
    }

    @Transactional
    public InsumoResponseDTO crear(InsumoRequestDTO dto) {
        TipoArticulo tipo = parseTipo(dto.tipo());
        UnidadMedida unidad = parseUnidad(dto.unidadMedida());
        MateriaPrima mp = new MateriaPrima();
        mp.setCodigo(codigoService.siguiente(tipo));
        mp.setTipo(tipo);
        mp.setNombre(dto.nombre().trim());
        mp.setFamilia(unidad.getFamilia());
        mp.setUnidadMedida(unidad);
        aplicarPresentacion(mp, dto);
        UnidadMedida unidadStock = unidadDeLaFamilia(mp, dto.stockUnidad(), unidad);
        mp.setStockActual(enBase(dto.stockActual(), unidadStock));
        mp.setStockMinimo(enBase(dto.stockMinimo(), unidadStock));

        MateriaPrima guardada = materiaPrimaRepository.save(mp);
        log.info("[INSUMO] Creado insumo '{}' ({}) con costo ${} por {}", guardada.getNombre(),
                guardada.getCodigo(), guardada.getCostoUnidadBase(), guardada.getFamilia().getUnidadBase());
        return toResponseDTO(guardada);
    }

    @Transactional
    public InsumoResponseDTO actualizar(Long id, InsumoRequestDTO dto) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));

        BigDecimal costoAnterior = mp.getCostoUnidadBase();
        mp.setNombre(dto.nombre().trim());
        UnidadMedida nueva = parseUnidad(dto.unidadMedida());
        if (nueva.getFamilia() != mp.getFamilia()) {
            validarCambioDeFamilia(mp, nueva);
            mp.setFamilia(nueva.getFamilia());
        }
        // Dentro de la misma familia la unidad para mostrar se cambia libremente.
        mp.setUnidadMedida(nueva);
        aplicarPresentacion(mp, dto);
        if (dto.stockMinimo() != null) {
            mp.setStockMinimo(enBase(dto.stockMinimo(), unidadDeLaFamilia(mp, dto.stockUnidad(), nueva)));
        }

        MateriaPrima actualizada = materiaPrimaRepository.save(mp);

        // Si cambió el costo, se recalculan costo y precio de los elaborados que la usan.
        if (costoAnterior.compareTo(actualizada.getCostoUnidadBase()) != 0) {
            recalcularRecetasConInsumo(actualizada.getId());
        }

        return toResponseDTO(actualizada);
    }

    @Transactional
    public InsumoResponseDTO ajustarStock(Long id, AjusteStockInsumoDTO dto) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));

        UnidadMedida unidad = unidadDeLaFamilia(mp, dto.unidad(), mp.getUnidadMedida());
        BigDecimal ajusteBase = unidad.aBase(dto.cantidad());
        BigDecimal nuevoStock = mp.getStockActual().add(ajusteBase);
        if (nuevoStock.signum() < 0) {
            throw new RecetaInvalidaException("El stock resultante no puede ser negativo (actual: "
                    + mp.getUnidadMedida().texto(mp.getStockActual()) + ", ajuste: "
                    + unidad.texto(ajusteBase) + ").");
        }

        mp.setStockActual(nuevoStock);
        MateriaPrima guardada = materiaPrimaRepository.save(mp);
        log.info("[INSUMO] Ajuste de stock para '{}': {}. Motivo: {}. Stock actual: {}",
                guardada.getNombre(), unidad.texto(ajusteBase), dto.motivo(),
                guardada.getUnidadMedida().texto(guardada.getStockActual()));

        return toResponseDTO(guardada);
    }

    /**
     * Costo por unidad base = precio / (cantidad de la presentación en unidad
     * base), con 4 decimales. Bolsa de 25 kg a $30.000 → $1,2000 por gramo.
     */
    private void aplicarPresentacion(MateriaPrima mp, InsumoRequestDTO dto) {
        UnidadMedida unidad = unidadDeLaFamilia(mp, dto.presentacionUnidad(), null);
        BigDecimal cantidadBase = unidad.aBase(dto.presentacionCantidad());
        mp.setPresentacionDescripcion(dto.presentacionDescripcion() != null && !dto.presentacionDescripcion().isBlank()
                ? dto.presentacionDescripcion().trim() : null);
        mp.setPresentacionCantidad(dto.presentacionCantidad());
        mp.setPresentacionUnidad(unidad);
        mp.setPresentacionPrecio(dto.presentacionPrecio());
        mp.setCostoUnidadBase(dto.presentacionPrecio().divide(cantidadBase, 4, RoundingMode.HALF_UP));
    }

    private static BigDecimal enBase(BigDecimal cantidad, UnidadMedida unidad) {
        return cantidad == null ? BigDecimal.ZERO : unidad.aBase(cantidad).setScale(3, RoundingMode.HALF_UP);
    }

    /** Unidad indicada (o la de reserva), que tiene que ser de la familia del insumo. */
    private UnidadMedida unidadDeLaFamilia(MateriaPrima mp, String unidadStr, UnidadMedida porDefecto) {
        UnidadMedida unidad = unidadStr == null || unidadStr.isBlank() ? porDefecto : parseUnidad(unidadStr);
        if (unidad == null) {
            throw new RecetaInvalidaException("Indique la unidad.");
        }
        if (!unidad.esDe(mp.getFamilia())) {
            throw new RecetaInvalidaException("La unidad " + unidad.name().toLowerCase() + " no corresponde a "
                    + mp.getNombre() + ", que se mide en " + mp.getFamilia().getDescripcion() + " ("
                    + nombres(mp.getFamilia()) + ").");
        }
        return unidad;
    }

    private static String nombres(FamiliaUnidad familia) {
        return String.join(", ", UnidadMedida.de(familia).stream().map(u -> u.name().toLowerCase()).toList());
    }

    /** Tipo elegido en el alta de Materia Prima; por defecto, materia prima. */
    private static TipoArticulo parseTipo(String tipo) {
        if (tipo == null || tipo.isBlank()) {
            return TipoArticulo.MATERIA_PRIMA;
        }
        try {
            TipoArticulo t = TipoArticulo.valueOf(tipo.trim().toUpperCase());
            if (t.esDeMateriaPrima()) {
                return t;
            }
        } catch (IllegalArgumentException ignored) {
            // cae al mensaje de abajo
        }
        throw new RecetaInvalidaException(
                "Tipo no válido: " + tipo + ". Elija materia prima, insumo o reventa + materia prima.");
    }

    /**
     * La familia (peso, volumen, longitud, unidades) no puede cambiar si hay
     * stock o recetas activas que lo usan: no se pueden convertir entre
     * familias. Reemplaza la regla E-10 (ahora la unidad para mostrar se
     * cambia libremente dentro de la familia).
     */
    private void validarCambioDeFamilia(MateriaPrima mp, UnidadMedida nueva) {
        List<String> motivos = new java.util.ArrayList<>();
        if (mp.getStockActual().signum() > 0) {
            motivos.add("tiene stock (" + mp.getUnidadMedida().texto(mp.getStockActual()) + ")");
        }
        List<String> recetas = recetaRepository.findRecetasByMateriaPrimaId(mp.getId()).stream()
                .map(Receta::getNombre)
                .toList();
        if (!recetas.isEmpty()) {
            motivos.add("se usa en recetas activas (" + String.join(", ", recetas) + ")");
        }
        if (!motivos.isEmpty()) {
            throw new RecetaInvalidaException("No se puede pasar " + mp.getNombre() + " de "
                    + mp.getFamilia().getDescripcion() + " a " + nueva.getFamilia().getDescripcion()
                    + " porque " + String.join(" y ", motivos) + ". Lleve el stock a 0 con un ajuste "
                    + "o cree un insumo nuevo.");
        }
    }

    /** Activa o desactiva el insumo (los insumos no se eliminan). */
    @Transactional
    public InsumoResponseDTO cambiarEstado(Long id, boolean activo) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));
        mp.setActivo(activo);
        log.info("[INSUMO] '{}' {}", mp.getNombre(), activo ? "activado" : "desactivado");
        return toResponseDTO(materiaPrimaRepository.save(mp));
    }

    @Transactional
    public void recalcularRecetasConInsumo(Long materiaPrimaId) {
        List<Receta> recetasAfectadas = recetaRepository.findRecetasByMateriaPrimaId(materiaPrimaId);
        for (Receta r : recetasAfectadas) {
            BigDecimal nuevoCosto = r.calcularCostoTotal();
            EspProducto producto = r.getProducto();
            if (producto != null) {
                producto.setPrecioCosto(nuevoCosto);
                producto.recalcularPrecioDesdeCostoYMargen();
                espProductoRepository.save(producto);
                log.info("[RECETA RECALCULO] Producto elaborado '{}' ({}) actualizado: nuevo costo ${}, nuevo precio venta ${}",
                        producto.getNombre(), producto.getCodigo(), producto.getPrecioCosto(), producto.getPrecioUnitario());
            }
        }
    }

    /** Unidad de una familia (CAJA es solo de productos). */
    private UnidadMedida parseUnidad(String unidadStr) {
        try {
            UnidadMedida u = UnidadMedida.valueOf(unidadStr.trim().toUpperCase());
            if (u.getFamilia() != null) {
                return u;
            }
        } catch (IllegalArgumentException | NullPointerException ignored) {
            // cae al mensaje de abajo
        }
        throw new RecetaInvalidaException("Unidad de medida no válida: " + unidadStr
                + ". Use gramo, kilo, mililitro, litro, centímetro, metro, unidad o docena.");
    }

    public InsumoResponseDTO toResponseDTO(MateriaPrima mp) {
        return new InsumoResponseDTO(
                mp.getId(),
                mp.getCodigo(),
                mp.getTipo().name(),
                mp.getNombre(),
                mp.getFamilia().name(),
                mp.getUnidadMedida().name(),
                mp.getFamilia().getUnidadBase().name(),
                mp.getCostoUnidadBase(),
                mp.getCostoUnitario(),
                mp.getPresentacionDescripcion(),
                mp.getPresentacionCantidad(),
                mp.getPresentacionUnidad() != null ? mp.getPresentacionUnidad().name() : null,
                mp.getPresentacionPrecio(),
                mp.getStockActual(),
                mp.getStockMinimo(),
                mp.isActivo()
        );
    }
}
