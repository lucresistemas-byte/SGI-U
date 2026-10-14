package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.ProductoInvalidoException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.CambioPrecioDTO;
import com.sgiu_group.sgiu.models.dtos.PaqueteRequestDTO;
import com.sgiu_group.sgiu.models.dtos.PaqueteResponseDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.ModoPrecio;
import com.sgiu_group.sgiu.models.entities.PaqueteArmado;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.PaqueteArmadoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Paquetes (PAQ-0001): se arman con insumos (caja, cinta, papel) y se venden
 * en el POS como una línea; lo que va adentro se cobra aparte. Precio = costo
 * del armado + monto fijo, redondeado hacia arriba a $100 (CostosService).
 */
@Service
@RequiredArgsConstructor
public class PaqueteService {

    private final EspProductoRepository productoRepository;
    private final PaqueteArmadoRepository armadoRepository;
    private final ArticuloStockRepository stockRepository;
    private final CategoriaRepository categoriaRepository;
    private final CodigoService codigoService;
    private final CostosService costosService;

    @Transactional(readOnly = true)
    public List<PaqueteResponseDTO> listar() {
        return productoRepository.findByTipoIn(Set.of(TipoArticulo.PAQUETE)).stream()
                .sorted((a, b) -> a.getCodigo().compareTo(b.getCodigo()))
                .map(p -> toResponseDTO(p, List.of()))
                .toList();
    }

    @Transactional(readOnly = true)
    public PaqueteResponseDTO obtener(Long id) {
        return toResponseDTO(buscar(id), List.of());
    }

    @Transactional
    public PaqueteResponseDTO crear(PaqueteRequestDTO dto) {
        validarArmado(dto);
        EspProducto paquete = new EspProducto(codigoService.siguiente(TipoArticulo.PAQUETE), dto.nombre().trim(),
                BigDecimal.ZERO);
        paquete.setTipo(TipoArticulo.PAQUETE);
        paquete.setModoPrecio(ModoPrecio.COSTO_MAS_FIJO);
        paquete.setMontoFijo(dto.montoFijo());
        paquete.setCategoria(categoria(dto.categoriaId()));
        paquete = productoRepository.save(paquete);
        stockRepository.save(new ArticuloStock(paquete, BigDecimal.ZERO));
        guardarArmado(paquete, dto);
        costosService.propagar(paquete, null, "Alta de " + paquete.getNombre());
        return toResponseDTO(paquete, List.of());
    }

    @Transactional
    public PaqueteResponseDTO actualizar(Long id, PaqueteRequestDTO dto) {
        EspProducto paquete = buscar(id);
        validarArmado(dto);
        CostosService.Foto antes = costosService.foto(paquete);
        paquete.setNombre(dto.nombre().trim());
        paquete.setMontoFijo(dto.montoFijo());
        paquete.setCategoria(categoria(dto.categoriaId()));
        armadoRepository.deleteByPaquete(paquete);
        armadoRepository.flush();
        guardarArmado(paquete, dto);
        List<CambioPrecioDTO> cambios = costosService.propagar(paquete, antes,
                "Cambio en el armado de " + paquete.getNombre() + " (" + paquete.getCodigo() + ")");
        return toResponseDTO(paquete, cambios);
    }

    @Transactional
    public PaqueteResponseDTO cambiarEstado(Long id, boolean activo) {
        EspProducto paquete = buscar(id);
        paquete.setActivo(activo);
        return toResponseDTO(productoRepository.save(paquete), List.of());
    }

    private EspProducto buscar(Long id) {
        return productoRepository.findById(id)
                .filter(p -> p.getTipo() == TipoArticulo.PAQUETE)
                .orElseThrow(() -> new RecursoNoEncontradoException("Paquete no encontrado con ID: " + id));
    }

    private Categoria categoria(Long id) {
        if (id == null) {
            return null;
        }
        return categoriaRepository.findById(id).filter(Categoria::isActivo)
                .orElseThrow(() -> new ProductoInvalidoException("La categoría elegida no existe o está desactivada."));
    }

    /** Solo insumos activos (o que ya estaban), sin repetir, con unidad de su familia. */
    private void validarArmado(PaqueteRequestDTO dto) {
        Set<Long> vistos = new HashSet<>();
        for (PaqueteRequestDTO.Fila f : dto.armado()) {
            EspProducto insumo = insumo(f.articuloId());
            if (!vistos.add(insumo.getId())) {
                throw new ProductoInvalidoException(insumo.getNombre() + " está dos veces en el armado.");
            }
            unidad(insumo, f.unidadMedida());
        }
    }

    private void guardarArmado(EspProducto paquete, PaqueteRequestDTO dto) {
        for (PaqueteRequestDTO.Fila f : dto.armado()) {
            EspProducto insumo = insumo(f.articuloId());
            armadoRepository.save(new PaqueteArmado(paquete, insumo, f.cantidad(), unidad(insumo, f.unidadMedida())));
        }
    }

    private EspProducto insumo(Long id) {
        EspProducto a = productoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Insumo no encontrado con ID: " + id));
        if (a.getTipo() != TipoArticulo.INSUMO) {
            throw new ProductoInvalidoException(a.getNombre()
                    + " no es un insumo: el armado de un paquete lleva insumos (cajas, cintas, papel...).");
        }
        if (!a.isActivo()) {
            throw new ProductoInvalidoException(a.getNombre() + " está desactivado. Reactívelo para usarlo en un paquete.");
        }
        return a;
    }

    private static UnidadMedida unidad(EspProducto insumo, String unidadStr) {
        if (unidadStr == null || unidadStr.isBlank()) {
            return insumo.getFamilia().getUnidadBase();
        }
        try {
            UnidadMedida u = UnidadMedida.valueOf(unidadStr.trim().toUpperCase());
            if (u.esDe(insumo.getFamilia())) {
                return u;
            }
        } catch (IllegalArgumentException ignored) {
            // cae al mensaje de abajo
        }
        throw new ProductoInvalidoException("La unidad " + unidadStr.toLowerCase() + " no corresponde a "
                + insumo.getNombre() + ", que se mide en " + insumo.getFamilia().getDescripcion() + ".");
    }

    private PaqueteResponseDTO toResponseDTO(EspProducto p, List<CambioPrecioDTO> cambios) {
        List<PaqueteArmado> armado = armadoRepository.findByPaqueteOrderById(p);
        List<PaqueteResponseDTO.Fila> filas = armado.stream()
                .map(a -> new PaqueteResponseDTO.Fila(
                        a.getId(),
                        a.getArticulo().getId(),
                        a.getArticulo().getCodigo(),
                        a.getArticulo().getNombre(),
                        a.getCantidad(),
                        a.getUnidadMedida().name(),
                        costosService.costoPor(a.getArticulo(), a.getUnidadMedida()),
                        costosService.costoFilaArmado(a).setScale(2, java.math.RoundingMode.HALF_UP),
                        a.getArticulo().getFamilia().name()))
                .toList();
        BigDecimal stock = stockRepository.findByEspProducto(p).map(ArticuloStock::getCantidad).orElse(BigDecimal.ZERO);
        return new PaqueteResponseDTO(
                p.getId(),
                p.getCodigo(),
                p.getNombre(),
                p.getCategoria() != null ? p.getCategoria().getId() : null,
                p.getCategoria() != null ? p.getCategoria().getNombre() : null,
                p.isActivo(),
                p.getPrecioCosto(),
                p.getMontoFijo(),
                p.getPrecioUnitario(),
                CostosService.ganancia(p.getPrecioUnitario(), p.getPrecioCosto()),
                p.unidadesDeVentaEn(stock),
                filas,
                cambios);
    }
}
