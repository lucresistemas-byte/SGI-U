package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.RecetaDetalleRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaDetalleResponseDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaResponseDTO;
import com.sgiu_group.sgiu.models.entities.*;
import com.sgiu_group.sgiu.models.dtos.ProductoElaboradoNuevoDTO;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
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

    private final RecetaRepository recetaRepository;
    private final RecetaDetalleRepository recetaDetalleRepository;
    private final MateriaPrimaRepository materiaPrimaRepository;
    private final ArticuloStockRepository stockRepository;
    private final CategoriaRepository categoriaRepository;
    private final EspProductoRepository espProductoRepository;

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
        validarCiclos(producto.getId(), dto.detalles(), new HashSet<>());
        return guardarNueva(producto, dto);
    }

    /**
     * La receta crea el producto elaborado (Punto 5): producto ELABORADO con
     * stock 0 y receta, en la misma transacción. Se valida la receta antes de
     * crear el producto; si algo falla, no queda nada creado.
     */
    private RecetaResponseDTO crearConProductoNuevo(RecetaRequestDTO dto) {
        ProductoElaboradoNuevoDTO nuevo = dto.productoNuevo();
        validarDuplicadosYExistencia(dto.detalles(), Set.of());

        String codigo = nuevo.codigo() != null && !nuevo.codigo().isBlank()
                ? nuevo.codigo().trim()
                : siguienteCodigoElaborado();
        if (espProductoRepository.existsByCodigo(codigo)) {
            throw new RecetaInvalidaException("Ya existe un producto con el código " + codigo + ".");
        }

        EspProducto producto = new EspProducto(codigo, nuevo.nombre().trim(), BigDecimal.ZERO);
        producto.setTipo(TipoArticulo.ELABORADO);
        producto.setVendible(nuevo.vendible() == null || nuevo.vendible());
        producto.setPorcentajeGanancia(nuevo.porcentajeGanancia() != null
                ? nuevo.porcentajeGanancia() : BigDecimal.ZERO);
        if (nuevo.categoriaId() != null) {
            producto.setCategoria(categoriaRepository.findById(nuevo.categoriaId()).orElse(null));
        }
        producto = espProductoRepository.save(producto);

        ArticuloStock stock = new ArticuloStock();
        stock.setEspProducto(producto);
        stock.setCantidad(0);
        stock.setStockMinimo(0);
        stockRepository.save(stock);

        return guardarNueva(producto, dto);
    }

    /** Código ELA-0001, ELA-0002, ... siguiente al mayor existente. */
    private String siguienteCodigoElaborado() {
        int mayor = espProductoRepository.findByCodigoStartingWith("ELA-").stream()
                .map(p -> p.getCodigo().substring(4))
                .filter(n -> n.matches("\\d+"))
                .mapToInt(Integer::parseInt)
                .max()
                .orElse(0);
        String codigo;
        do {
            codigo = String.format("ELA-%04d", ++mayor);
        } while (espProductoRepository.existsByCodigo(codigo));
        return codigo;
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

    private RecetaResponseDTO guardarNueva(EspProducto producto, RecetaRequestDTO dto) {
        Receta receta = new Receta(
                producto,
                dto.nombre().trim(),
                dto.descripcion(),
                dto.costosAdicionales() != null ? dto.costosAdicionales() : BigDecimal.ZERO
        );

        poblarDetalles(receta, dto.detalles());

        Receta guardada = recetaRepository.save(receta);

        // Recalcular y actualizar costo y precio en el producto elaborado
        actualizarCostosProductoElaborado(guardada);

        log.info("[RECETA] Creada receta '{}' para producto '{}'. Costo total: ${}",
                guardada.getNombre(), producto.getNombre(), guardada.calcularCostoTotal());
        return toResponseDTO(guardada);
    }

    @Transactional
    public RecetaResponseDTO actualizar(Long id, RecetaRequestDTO dto) {
        Receta receta = recetaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Receta no encontrada con ID: " + id));

        // Un insumo que ya estaba en la receta puede quedar aunque se haya
        // desactivado; uno nuevo tiene que estar activo.
        Set<Long> yaEnLaReceta = new HashSet<>();
        receta.getDetalles().forEach(d -> yaEnLaReceta.add(d.getMateriaPrima().getId()));
        validarDuplicadosYExistencia(dto.detalles(), yaEnLaReceta);
        validarCiclos(receta.getProducto().getId(), dto.detalles(), new HashSet<>());

        receta.setNombre(dto.nombre().trim());
        receta.setDescripcion(dto.descripcion());
        receta.setCostosAdicionales(dto.costosAdicionales() != null ? dto.costosAdicionales() : BigDecimal.ZERO);

        receta.getDetalles().clear();
        poblarDetalles(receta, dto.detalles());

        Receta guardada = recetaRepository.save(receta);
        // Una receta inactiva no participa en el costo del producto.
        if (guardada.isActivo()) {
            actualizarCostosProductoElaborado(guardada);
        }

        log.info("[RECETA] Actualizada receta ID {} ('{}'). Nuevo costo: ${}",
                guardada.getId(), guardada.getNombre(), guardada.calcularCostoTotal());
        return toResponseDTO(guardada);
    }

    private void validarDuplicadosYExistencia(List<RecetaDetalleRequestDTO> detalles,
                                              Set<Long> insumosPermitidosInactivos) {
        Set<Long> insumosVistos = new HashSet<>();
        for (RecetaDetalleRequestDTO d : detalles) {
            MateriaPrima mp = materiaPrimaRepository.findById(d.materiaPrimaId())
                    .orElseThrow(() -> new RecursoNoEncontradoException("Materia prima no encontrada con ID: " + d.materiaPrimaId()));
            if (!insumosVistos.add(d.materiaPrimaId())) {
                throw new RecetaInvalidaException("El insumo " + mp.getNombre() + " está dos veces en la receta.");
            }
            if (!mp.isActivo() && !insumosPermitidosInactivos.contains(mp.getId())) {
                throw new RecetaInvalidaException("El insumo " + mp.getNombre()
                        + " está desactivado. Reactívelo para usarlo en una receta.");
            }
        }
    }

    private void validarCiclos(Long productoElaboradoId, List<RecetaDetalleRequestDTO> detalles, Set<Long> visitados) {
        visitados.add(productoElaboradoId);

        for (RecetaDetalleRequestDTO d : detalles) {
            MateriaPrima mp = materiaPrimaRepository.findById(d.materiaPrimaId()).orElse(null);
            if (mp != null && mp.getProducto() != null) {
                Long subProductoId = mp.getProducto().getId();
                if (subProductoId.equals(productoElaboradoId) || visitados.contains(subProductoId)) {
                    throw new RecetaInvalidaException("Dependencia circular (ciclo) detectada entre insumos y producto elaborado (ID: " + subProductoId + ")");
                }

                // Si este sub-producto a su vez tiene una receta, exploramos sus insumos
                Optional<Receta> subRecetaOpt = recetaRepository.findByProducto_IdAndActivoTrue(subProductoId);
                if (subRecetaOpt.isPresent()) {
                    List<RecetaDetalleRequestDTO> subDetalles = subRecetaOpt.get().getDetalles().stream()
                            .map(sd -> new RecetaDetalleRequestDTO(sd.getMateriaPrima().getId(), sd.getCantidad(), sd.getUnidadMedida().name()))
                            .toList();
                    validarCiclos(subProductoId, subDetalles, new HashSet<>(visitados));
                }
            }
        }
    }

    private void poblarDetalles(Receta receta, List<RecetaDetalleRequestDTO> detallesDTO) {
        for (RecetaDetalleRequestDTO d : detallesDTO) {
            MateriaPrima mp = materiaPrimaRepository.findById(d.materiaPrimaId())
                    .orElseThrow(() -> new RecursoNoEncontradoException("Materia prima no encontrada: " + d.materiaPrimaId()));

            UnidadMedida unidad = mp.getUnidadMedida();
            if (d.unidadMedida() != null && !d.unidadMedida().isBlank()) {
                try {
                    unidad = UnidadMedida.valueOf(d.unidadMedida().trim().toUpperCase());
                } catch (IllegalArgumentException ignored) {}
            }

            RecetaDetalle detalle = new RecetaDetalle(receta, mp, d.cantidad(), unidad);
            receta.addDetalle(detalle);
        }
    }

    private void actualizarCostosProductoElaborado(Receta receta) {
        BigDecimal nuevoCosto = receta.calcularCostoTotal();
        EspProducto producto = receta.getProducto();
        if (producto != null) {
            producto.setPrecioCosto(nuevoCosto);
            producto.recalcularPrecioDesdeCostoYMargen();
            espProductoRepository.save(producto);
        }
    }

    public RecetaResponseDTO toResponseDTO(Receta r) {
        List<RecetaDetalleResponseDTO> detallesDTO = r.getDetalles().stream()
                .map(d -> new RecetaDetalleResponseDTO(
                        d.getId(),
                        d.getMateriaPrima().getId(),
                        d.getMateriaPrima().getCodigo(),
                        d.getMateriaPrima().getNombre(),
                        d.getCantidad(),
                        d.getUnidadMedida().name(),
                        d.getMateriaPrima().getCostoUnitario(),
                        d.calcularSubtotal()
                ))
                .toList();

        return new RecetaResponseDTO(
                r.getId(),
                r.getProducto().getCodigo(),
                r.getProducto().getNombre(),
                r.getNombre(),
                r.getDescripcion(),
                r.getCostosAdicionales(),
                r.calcularCostoTotal(),
                detallesDTO,
                r.isActivo(),
                r.getProducto().isActivo()
        );
    }
}
