package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.RecetaInactivaExistenteException;
import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.RecetaDetalleRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaDetalleResponseDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.RecetaResponseDTO;
import com.sgiu_group.sgiu.models.entities.*;
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
    private final EspProductoRepository espProductoRepository;

    @Transactional(readOnly = true)
    public List<RecetaResponseDTO> listarTodas(boolean incluirInactivas) {
        List<Receta> recetas = incluirInactivas
                ? recetaRepository.findAll()
                : recetaRepository.findByActivoTrue();
        return recetas.stream()
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
        EspProducto producto = espProductoRepository.findByCodigo(dto.espProductoCodigo().trim())
                .orElseThrow(() -> new RecursoNoEncontradoException("Producto no encontrado: " + dto.espProductoCodigo()));

        Optional<Receta> existente = recetaRepository.findByProducto(producto);
        if (existente.isPresent() && existente.get().isActivo()) {
            throw new RecetaInvalidaException("El producto ya cuenta con una receta activa (ID: " + existente.get().getId() + ")");
        }
        if (existente.isPresent()) {
            // Un producto tiene una sola receta (UNIQUE): se reactiva la existente.
            throw new RecetaInactivaExistenteException(
                    "El producto " + producto.getNombre() + " ya tiene una receta desactivada ("
                            + existente.get().getNombre() + "). Puede reactivarla y editarla.",
                    existente.get().getId());
        }

        validarDuplicadosYExistencia(dto.detalles(), Set.of());
        validarCiclos(producto.getId(), dto.detalles(), new HashSet<>());

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

    /** Activa o desactiva la receta. Al reactivarla, vuelve a costear el producto. */
    @Transactional
    public RecetaResponseDTO cambiarEstado(Long id, boolean activo) {
        Receta receta = recetaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Receta no encontrada con ID: " + id));

        receta.setActivo(activo);
        Receta guardada = recetaRepository.save(receta);
        if (activo) {
            actualizarCostosProductoElaborado(guardada);
        }
        log.info("[RECETA] Receta ID {} {}", id, activo ? "activada" : "desactivada");
        return toResponseDTO(guardada);
    }

    private void validarDuplicadosYExistencia(List<RecetaDetalleRequestDTO> detalles,
                                              Set<Long> insumosPermitidosInactivos) {
        Set<Long> insumosVistos = new HashSet<>();
        for (RecetaDetalleRequestDTO d : detalles) {
            if (!insumosVistos.add(d.materiaPrimaId())) {
                throw new RecetaInvalidaException("Insumo duplicado en la receta. ID de insumo: " + d.materiaPrimaId());
            }
            MateriaPrima mp = materiaPrimaRepository.findById(d.materiaPrimaId())
                    .orElseThrow(() -> new RecursoNoEncontradoException("Materia prima no encontrada con ID: " + d.materiaPrimaId()));
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
                r.isActivo()
        );
    }
}
