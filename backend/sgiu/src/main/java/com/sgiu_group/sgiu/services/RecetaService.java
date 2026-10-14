package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.CambioPrecioDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaDetalleRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaDetalleResponseDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaResponseDTO;
import com.sgiu_group.sgiu.models.entities.*;
import com.sgiu_group.sgiu.models.dtos.ProductoElaboradoNuevoDTO;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.RecetaDetalleRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecetaService {

    private final CodigoService codigoService;
    private final RecetaRepository recetaRepository;
    private final RecetaDetalleRepository recetaDetalleRepository;
    private final ArticuloStockRepository stockRepository;
    private final CategoriaRepository categoriaRepository;
    private final EspProductoRepository espProductoRepository;
    private final CostosService costosService;

    @Transactional(readOnly = true)
    public List<RecetaResponseDTO> listarTodas() {
        return recetaRepository.findAll().stream()
                .map(this::toResponseDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public RecetaResponseDTO obtenerPorId(Long id) {
        Receta receta = recetaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Receta no encontrada con ID: " + id));
        return toResponseDTO(receta);
    }

    @Transactional(readOnly = true)
    public RecetaResponseDTO obtenerPorCodigoProducto(String codigo) {
        Receta receta = recetaRepository.findByProducto_CodigoAndActivoTrue(codigo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Receta no encontrada para el producto: " + codigo));
        return toResponseDTO(receta);
    }

    @Transactional
    public RecetaResponseDTO crear(RecetaRequestDTO dto) {
        boolean hayExistente = dto.espProductoCodigo() != null && !dto.espProductoCodigo().isBlank();
        if (hayExistente == (dto.productoNuevo() != null)) {
            throw new RecetaInvalidaException(
                    "Indique un producto elaborado existente o los datos de uno nuevo (uno de los dos).");
        }
        if (!hayExistente) {
            return crearConProductoNuevo(dto);
        }

        EspProducto producto = espProductoRepository.findByCodigo(dto.espProductoCodigo().trim())
                .orElseThrow(() -> new RecursoNoEncontradoException("Producto no encontrado: " + dto.espProductoCodigo()));
        if (!producto.getTipo().tieneReceta()) {
            throw new RecetaInvalidaException("Solo los productos elaborados tienen receta: "
                    + producto.getNombre() + " es de " + descripcionTipo(producto.getTipo()) + ".");
        }

        // Un producto tiene una sola receta (UNIQUE), que siempre está visible.
        Optional<Receta> existente = recetaRepository.findByProducto(producto);
        if (existente.isPresent()) {
            throw new RecetaInvalidaException("El producto " + producto.getNombre() + " ya tiene una receta ("
                    + existente.get().getNombre() + "). Edítela en lugar de crear otra.");
        }

        validarDuplicadosYExistencia(dto.detalles(), Set.of());
        validarCiclos(producto, dto.detalles());
        validarRinde(producto, dto);
        return guardarNueva(producto, dto, false);
    }

    /**
     * La receta crea el producto elaborado (Punto 5): producto ELABORADO con
     * stock 0 y receta, en la misma transacción. Se valida la receta antes de
     * crear el producto; si algo falla, no queda nada creado.
     */
    private RecetaResponseDTO crearConProductoNuevo(RecetaRequestDTO dto) {
        ProductoElaboradoNuevoDTO nuevo = dto.productoNuevo();
        validarDuplicadosYExistencia(dto.detalles(), Set.of());
        boolean vendible = nuevo.vendible() == null || nuevo.vendible();
        if (!vendible) {
            unidadDelRinde(nuevo.nombre(), dto.rindeUnidadMedida());
        }
        // La categoría es obligatoria y debe estar activa (se crea desde el
        // botón "+" del armador si todavía no existe).
        if (nuevo.categoriaId() == null) {
            throw new RecetaInvalidaException("Elija una categoría para el producto nuevo.");
        }
        Categoria categoria = categoriaRepository.findById(nuevo.categoriaId())
                .filter(Categoria::isActivo)
                .orElseThrow(() -> new RecetaInvalidaException(
                        "La categoría elegida no existe o está desactivada."));

        String codigo = codigoService.siguiente(TipoArticulo.ELABORADO);
        EspProducto producto = new EspProducto(codigo, nuevo.nombre().trim(), BigDecimal.ZERO);
        producto.setTipo(TipoArticulo.ELABORADO);
        producto.setVendible(vendible);
        producto.setPorcentajeGanancia(nuevo.porcentajeGanancia() != null
                ? nuevo.porcentajeGanancia() : BigDecimal.ZERO);
        producto.setCategoria(categoria);
        producto = espProductoRepository.save(producto);

        stockRepository.save(new ArticuloStock(producto, BigDecimal.ZERO));

        return guardarNueva(producto, dto, true);
    }

    private static String descripcionTipo(TipoArticulo tipo) {
        return switch (tipo) {
            case REVENTA -> "reventa";
            case MATERIA_PRIMA -> "materia prima";
            case INSUMO -> "insumo";
            case REVENTA_MATERIA_PRIMA -> "reventa y materia prima";
            case PAQUETE -> "tipo paquete";
            case ELABORADO -> "elaborado";
        };
    }

    /** [productoNuevo]: el elaborado nace con la receta (su primer precio no va al historial). */
    private RecetaResponseDTO guardarNueva(EspProducto producto, RecetaRequestDTO dto, boolean productoNuevo) {
        Receta receta = new Receta(
                producto,
                dto.nombre().trim(),
                dto.descripcion(),
                dto.costosAdicionales() != null ? dto.costosAdicionales() : BigDecimal.ZERO
        );

        aplicarRinde(receta, dto);
        poblarDetalles(receta, dto.detalles());

        Receta guardada = recetaRepository.save(receta);
        // Costo y precio del elaborado (y de lo que lo use, si es preparación base).
        CostosService.Foto antes = productoNuevo ? null : costosService.foto(producto);
        List<CambioPrecioDTO> cambios = costosService.propagar(producto, antes,
                "Receta nueva de " + producto.getNombre() + " (" + producto.getCodigo() + ")");

        log.info("[RECETA] Creada receta '{}' para producto '{}'. Costo total: ${}",
                guardada.getNombre(), producto.getNombre(), costosService.costoReceta(guardada));
        return toResponseDTO(guardada, cambios);
    }

    @Transactional
    public RecetaResponseDTO actualizar(Long id, RecetaRequestDTO dto) {
        Receta receta = recetaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Receta no encontrada con ID: " + id));

        // Un componente que ya estaba en la receta puede quedar aunque se haya
        // desactivado; uno nuevo tiene que estar activo.
        Set<Long> yaEnLaReceta = new HashSet<>();
        receta.getDetalles().forEach(d -> yaEnLaReceta.add(d.getArticulo().getId()));
        validarDuplicadosYExistencia(dto.detalles(), yaEnLaReceta);
        EspProducto producto = receta.getProducto();
        validarCiclos(producto, dto.detalles());
        validarRinde(producto, dto);
        CostosService.Foto antes = costosService.foto(producto);

        receta.setNombre(dto.nombre().trim());
        receta.setDescripcion(dto.descripcion());
        receta.setCostosAdicionales(dto.costosAdicionales() != null ? dto.costosAdicionales() : BigDecimal.ZERO);

        aplicarRinde(receta, dto);
        receta.getDetalles().clear();
        poblarDetalles(receta, dto.detalles());

        Receta guardada = recetaRepository.save(receta);
        // Una receta inactiva no participa en el costo del producto. Si está
        // activa, se recalculan el elaborado y todo lo que depende de él.
        List<CambioPrecioDTO> cambios = guardada.isActivo()
                ? costosService.propagar(producto, antes,
                        "Cambio en la receta de " + producto.getNombre() + " (" + producto.getCodigo() + ")")
                : List.of();

        log.info("[RECETA] Actualizada receta ID {} ('{}'). Nuevo costo: ${}",
                guardada.getId(), guardada.getNombre(), costosService.costoReceta(guardada));
        return toResponseDTO(guardada, cambios);
    }

    private void validarDuplicadosYExistencia(List<RecetaDetalleRequestDTO> detalles,
                                              Set<Long> permitidosInactivos) {
        Set<Long> vistos = new HashSet<>();
        for (RecetaDetalleRequestDTO d : detalles) {
            EspProducto articulo = componente(d.articuloId());
            if (!vistos.add(d.articuloId())) {
                throw new RecetaInvalidaException(articulo.getNombre() + " está dos veces en la receta.");
            }
            // La unidad se valida antes de crear nada (también el producto nuevo).
            unidadDeLaFila(articulo, d.unidadMedida());
            if (!articulo.isActivo() && !permitidosInactivos.contains(articulo.getId())) {
                throw new RecetaInvalidaException(articulo.getNombre()
                        + " está desactivado. Reactívelo para usarlo en una receta.");
            }
        }
    }

    /**
     * Componente de receta: materia prima, insumo, reventa + materia prima o
     * preparación base (que rinde en peso o volumen).
     */
    private EspProducto componente(Long articuloId) {
        EspProducto articulo = espProductoRepository.findById(articuloId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Artículo no encontrado con ID: " + articuloId));
        if (articulo.esPreparacionBase()) {
            if (articulo.getFamilia() == null) {
                throw new RecetaInvalidaException(articulo.getNombre() + " todavía no tiene un rinde en peso o "
                        + "volumen: guarde su receta indicando cuánto rinde (p. ej. 800 g).");
            }
            return articulo;
        }
        if (!articulo.getTipo().esDeMateriaPrima()) {
            throw new RecetaInvalidaException(articulo.getNombre() + " es de " + descripcionTipo(articulo.getTipo())
                    + " y no se puede usar en recetas. Use materias primas, insumos, reventa + materia prima "
                    + "o preparaciones base.");
        }
        return articulo;
    }

    /**
     * Rechaza un ciclo: una preparación base de la receta no puede usar,
     * directa o indirectamente, el producto que se está guardando (DFS sobre
     * los componentes).
     */
    private void validarCiclos(EspProducto producto, List<RecetaDetalleRequestDTO> detalles) {
        for (RecetaDetalleRequestDTO d : detalles) {
            EspProducto componente = componente(d.articuloId());
            if (!componente.esPreparacionBase()) {
                continue;
            }
            if (componente.getId().equals(producto.getId())
                    || costosService.componentesTransitivos(componente.getId()).contains(producto.getId())) {
                throw new RecetaInvalidaException("No se puede usar " + componente.getNombre() + " en la receta de "
                        + producto.getNombre() + ": " + componente.getNombre() + " ya usa " + producto.getNombre()
                        + " (directa o indirectamente) y se formaría un ciclo.");
            }
        }
    }

    /**
     * Preparación base: rinde en peso o volumen. Si ya se usa en recetas, no
     * puede pasar de peso a volumen (las filas que la usan quedarían mal).
     */
    private void validarRinde(EspProducto producto, RecetaRequestDTO dto) {
        if (!producto.esPreparacionBase()) {
            return;
        }
        UnidadMedida unidad = unidadDelRinde(producto.getNombre(), dto.rindeUnidadMedida());
        if (producto.getFamilia() != null && producto.getFamilia() != unidad.getFamilia()) {
            List<String> recetas = recetaRepository.findRecetasByArticuloId(producto.getId()).stream()
                    .map(Receta::getNombre).toList();
            if (!recetas.isEmpty()) {
                throw new RecetaInvalidaException("No se puede pasar el rinde de " + producto.getNombre() + " de "
                        + producto.getFamilia().getDescripcion() + " a " + unidad.getFamilia().getDescripcion()
                        + " porque se usa en recetas activas (" + String.join(", ", recetas) + ").");
            }
        }
    }

    private static UnidadMedida unidadDelRinde(String nombre, String unidadStr) {
        UnidadMedida unidad = null;
        try {
            unidad = unidadStr == null ? null : UnidadMedida.valueOf(unidadStr.trim().toUpperCase());
        } catch (IllegalArgumentException ignored) {
            // cae al mensaje de abajo
        }
        if (unidad == null || !(unidad.esDe(FamiliaUnidad.PESO) || unidad.esDe(FamiliaUnidad.VOLUMEN))) {
            throw new RecetaInvalidaException("Indique cuánto rinde " + nombre.trim()
                    + " en peso o volumen (gramo, kilo, mililitro o litro): es una preparación base.");
        }
        return unidad;
    }

    /**
     * Cada fila se guarda con su cantidad y unidad y con la cantidad en
     * unidad base. La unidad tiene que ser de la familia del insumo; sin
     * unidad, la base (la más chica).
     */
    private void poblarDetalles(Receta receta, List<RecetaDetalleRequestDTO> detallesDTO) {
        for (RecetaDetalleRequestDTO d : detallesDTO) {
            EspProducto articulo = componente(d.articuloId());
            receta.addDetalle(new RecetaDetalle(receta, articulo, d.cantidad(), unidadDeLaFila(articulo, d.unidadMedida())));
        }
    }

    private static UnidadMedida unidadDeLaFila(EspProducto articulo, String unidadStr) {
        if (unidadStr == null || unidadStr.isBlank()) {
            return articulo.getFamilia().getUnidadBase();
        }
        UnidadMedida unidad;
        try {
            unidad = UnidadMedida.valueOf(unidadStr.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RecetaInvalidaException("Unidad de medida no válida: " + unidadStr);
        }
        if (!unidad.esDe(articulo.getFamilia())) {
            throw new RecetaInvalidaException("La unidad " + unidad.name().toLowerCase() + " no corresponde a "
                    + articulo.getNombre() + ", que se mide en " + articulo.getFamilia().getDescripcion() + " ("
                    + String.join(", ", UnidadMedida.de(articulo.getFamilia()).stream()
                            .map(u -> u.name().toLowerCase()).toList()) + ").");
        }
        return unidad;
    }

    /**
     * Rinde de la receta. En una preparación base es peso o volumen ("800 g"):
     * el producto toma esa familia y unidad, y así se usa como componente.
     */
    private static void aplicarRinde(Receta receta, RecetaRequestDTO dto) {
        receta.setRinde(dto.rinde());
        EspProducto producto = receta.getProducto();
        if (producto.esPreparacionBase()) {
            UnidadMedida unidad = unidadDelRinde(producto.getNombre(), dto.rindeUnidadMedida());
            receta.setRindeUnidadMedida(unidad);
            receta.setRindeUnidad(unidad.getAbreviatura());
            producto.setFamilia(unidad.getFamilia());
            producto.setUnidadMedida(unidad);
        } else {
            receta.setRindeUnidadMedida(null);
            receta.setRindeUnidad(dto.rindeUnidad() != null && !dto.rindeUnidad().isBlank()
                    ? dto.rindeUnidad().trim() : "unidades");
        }
    }

    public RecetaResponseDTO toResponseDTO(Receta r) {
        return toResponseDTO(r, List.of());
    }

    public RecetaResponseDTO toResponseDTO(Receta r, List<CambioPrecioDTO> cambios) {
        List<RecetaDetalleResponseDTO> detallesDTO = r.getDetalles().stream()
                .map(d -> new RecetaDetalleResponseDTO(
                        d.getId(),
                        d.getArticulo().getId(),
                        d.getArticulo().getCodigo(),
                        d.getArticulo().getNombre(),
                        d.getArticulo().getTipo().name(),
                        d.getCantidad(),
                        d.getUnidadMedida().name(),
                        costosService.costoPor(d.getArticulo(), d.getUnidadMedida()),
                        costosService.subtotalFila(d),
                        d.getCantidadBase(),
                        d.getArticulo().getFamilia().getUnidadBase().name(),
                        d.getArticulo().getFamilia().name()
                ))
                .toList();

        EspProducto producto = r.getProducto();
        BigDecimal costoPorUnidad = costosService.costoUnitario(r);
        boolean base = producto.esPreparacionBase();
        return new RecetaResponseDTO(
                r.getId(),
                producto.getCodigo(),
                producto.getNombre(),
                r.getNombre(),
                r.getDescripcion(),
                r.getCostosAdicionales(),
                costosService.costoReceta(r),
                detallesDTO,
                r.isActivo(),
                producto.isActivo(),
                r.getRinde(),
                r.getRindeUnidad(),
                costoPorUnidad,
                producto.getPorcentajeGanancia(),
                producto.getPrecioUnitario(),
                base ? null : CostosService.ganancia(producto.getPrecioUnitario(), producto.getPrecioCosto()),
                producto.getModoPrecio().name(),
                base,
                r.getRindeUnidadMedida() != null ? r.getRindeUnidadMedida().name() : null,
                base ? producto.getCostoUnidadBase() : null,
                cambios
        );
    }
}
