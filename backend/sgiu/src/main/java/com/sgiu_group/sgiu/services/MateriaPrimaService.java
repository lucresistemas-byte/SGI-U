package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.AjusteStockInsumoDTO;
import com.sgiu_group.sgiu.models.dtos.InsumoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.InsumoResponseDTO;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.MateriaPrima;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MateriaPrimaService {

    private final MateriaPrimaRepository materiaPrimaRepository;
    private final RecetaRepository recetaRepository;
    private final EspProductoRepository espProductoRepository;

    @Transactional(readOnly = true)
    public List<InsumoResponseDTO> listarTodos() {
        return materiaPrimaRepository.findByActivoTrue().stream()
                .map(this::toResponseDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public InsumoResponseDTO obtenerPorId(Long id) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .filter(MateriaPrima::isActivo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));
        return toResponseDTO(mp);
    }

    @Transactional
    public InsumoResponseDTO crear(InsumoRequestDTO dto) {
        if (materiaPrimaRepository.existsByCodigo(dto.codigo())) {
            throw new RecetaInvalidaException("Ya existe un insumo con el código: " + dto.codigo());
        }

        UnidadMedida unidad = parseUnidad(dto.unidadMedida());
        MateriaPrima mp = new MateriaPrima(
                dto.codigo().trim(),
                dto.nombre().trim(),
                dto.costoUnitario(),
                unidad,
                dto.stockActual() != null ? dto.stockActual() : 0,
                dto.stockMinimo() != null ? dto.stockMinimo() : 0
        );

        MateriaPrima guardada = materiaPrimaRepository.save(mp);
        log.info("[INSUMO] Creado insumo '{}' ({}) con costo unitario ${}", guardada.getNombre(), guardada.getCodigo(), guardada.getCostoUnitario());
        return toResponseDTO(guardada);
    }

    @Transactional
    public InsumoResponseDTO actualizar(Long id, InsumoRequestDTO dto) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .filter(MateriaPrima::isActivo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));

        BigDecimal costoAnterior = mp.getCostoUnitario();
        mp.setNombre(dto.nombre().trim());
        mp.setCostoUnitario(dto.costoUnitario());
        if (dto.unidadMedida() != null) {
            mp.setUnidadMedida(parseUnidad(dto.unidadMedida()));
        }
        if (dto.stockMinimo() != null) {
            mp.setStockMinimo(dto.stockMinimo());
        }

        MateriaPrima actualizada = materiaPrimaRepository.save(mp);

        // Recálculo automático de costo y precio de productos elaborados si cambió el costo unitario
        if (costoAnterior.compareTo(actualizada.getCostoUnitario()) != 0) {
            recalcularRecetasConInsumo(actualizada.getId());
        }

        return toResponseDTO(actualizada);
    }

    @Transactional
    public InsumoResponseDTO ajustarStock(Long id, AjusteStockInsumoDTO dto) {
        MateriaPrima mp = materiaPrimaRepository.findById(id)
                .filter(MateriaPrima::isActivo)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));

        int nuevoStock = mp.getStockActual() + dto.cantidad();
        if (nuevoStock < 0) {
            throw new RecetaInvalidaException("El stock resultante no puede ser negativo (actual: " + mp.getStockActual() + ", ajuste: " + dto.cantidad() + ")");
        }

        mp.setStockActual(nuevoStock);
        MateriaPrima guardada = materiaPrimaRepository.save(mp);
        log.info("[INSUMO] Ajuste de stock para '{}': {} unidades. Motivo: {}. Stock actual: {}",
                guardada.getNombre(), dto.cantidad(), dto.motivo(), guardada.getStockActual());

        return toResponseDTO(guardada);
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

    private UnidadMedida parseUnidad(String unidadStr) {
        if (unidadStr == null || unidadStr.isBlank()) {
            return UnidadMedida.UNIDAD;
        }
        try {
            return UnidadMedida.valueOf(unidadStr.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RecetaInvalidaException("Unidad de medida no válida: " + unidadStr);
        }
    }

    public InsumoResponseDTO toResponseDTO(MateriaPrima mp) {
        return new InsumoResponseDTO(
                mp.getId(),
                mp.getCodigo(),
                mp.getNombre(),
                mp.getCostoUnitario(),
                mp.getUnidadMedida().name(),
                mp.getStockActual(),
                mp.getStockMinimo(),
                mp.isActivo()
        );
    }
}
