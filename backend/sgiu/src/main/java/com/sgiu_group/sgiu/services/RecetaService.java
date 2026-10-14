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
        producto.setVendible(nuevo.vendible() == null || nuevo.vendible());
        producto.setPorcentajeGanancia(nuevo.porcentajeGanancia() != null
                ? nuevo.porcentajeGanancia() : BigDecimal.ZERO);
        producto.setCategoria(categoria);
        producto = espProductoRepository.save(producto);

        stockRepository.save(new ArticuloStock(producto, BigDecimal.ZERO));

        return guardarNueva(producto, dto);
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

        aplicarRinde(receta, dto);
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

        // Un componente que ya estaba en la receta puede quedar aunque se haya
        // desactivado; uno nuevo tiene que estar activo.
        Set<Long> yaEnLaReceta = new HashSet<>();
        receta.getDetalles().forEach(d -> yaEnLaReceta.add(d.getArticulo().getId()));
        validarDuplicadosYExistencia(dto.detalles(), yaEnLaReceta);

        receta.setNombre(dto.nombre().trim());
        receta.setDescripcion(dto.descripcion());
        receta.setCostosAdicionales(dto.costosAdicionales() != null ? dto.costosAdicionales() : BigDecimal.ZERO);

        aplicarRinde(receta, dto);
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
     * Componente de receta: materia prima, insumo o reventa + materia prima.
     * (Las preparaciones base como componente llegan en la etapa 4.)
     */
    private EspProducto componente(Long articuloId) {
        EspProducto articulo = espProductoRepository.findById(articuloId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Artículo no encontrado con ID: " + articuloId));
        if (!articulo.getTipo().esDeMateriaPrima()) {
            throw new RecetaInvalidaException(articulo.getNombre() + " es de " + descripcionTipo(articulo.getTipo())
                    + " y no se puede usar en recetas. Use materias primas, insumos o reventa + materia prima.");
        }
        return articulo;
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

    private static void aplicarRinde(Receta receta, RecetaRequestDTO dto) {
        receta.setRinde(dto.rinde());
        receta.setRindeUnidad(dto.rindeUnidad() != null && !dto.rindeUnidad().isBlank()
                ? dto.rindeUnidad().trim() : "unidades");
    }

    private void actualizarCostosProductoElaborado(Receta receta) {
        receta.aplicarCostoAlProducto();
        if (receta.getProducto() != null) {
            espProductoRepository.save(receta.getProducto());
        }
    }

    public RecetaResponseDTO toResponseDTO(Receta r) {
        List<RecetaDetalleResponseDTO> detallesDTO = r.getDetalles().stream()
                .map(d -> new RecetaDetalleResponseDTO(
                        d.getId(),
                        d.getArticulo().getId(),
                        d.getArticulo().getCodigo(),
                        d.getArticulo().getNombre(),
                        d.getArticulo().getTipo().name(),
                        d.getCantidad(),
                        d.getUnidadMedida().name(),
                        d.getArticulo().costoPor(d.getUnidadMedida()).setScale(4, java.math.RoundingMode.HALF_UP),
                        d.calcularSubtotal(),
                        d.getCantidadBase(),
                        d.getArticulo().getFamilia().getUnidadBase().name(),
                        d.getArticulo().getFamilia().name()
                ))
                .toList();

        EspProducto producto = r.getProducto();
        return new RecetaResponseDTO(
                r.getId(),
                producto.getCodigo(),
                producto.getNombre(),
                r.getNombre(),
                r.getDescripcion(),
                r.getCostosAdicionales(),
                r.calcularCostoTotal(),
                detallesDTO,
                r.isActivo(),
                producto.isActivo(),
                r.getRinde(),
                r.getRindeUnidad(),
                r.calcularCostoPorUnidad(),
                producto.getPorcentajeGanancia(),
                producto.getPrecioUnitario()
        );
    }
}
