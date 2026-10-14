package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.exceptions.ProductoInvalidoException;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final CodigoService codigoService;
    private final EspProductoRepository productoRepository;
    private final ArticuloStockRepository stockRepository;
    private final CategoriaRepository categoriaRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo(String categoria) {
        return getCatalogo(categoria, null, null);
    }

    /**
     * Productos: los artículos de tipos que se venden (elaborado, reventa,
     * reventa + materia prima, paquete). Filtros opcionales: [tipo] (ver
     * TipoArticulo) y [vendible] (true = lo que se vende en el POS: activo, de
     * un tipo vendible y que no sea preparación base).
     */
    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo(String categoria, String tipo, Boolean vendible) {
        String filtroCategoria = (categoria != null && !categoria.isBlank()) ? categoria.trim() : null;
        List<ProductoCatalogoDTO> catalogo = productoRepository
                .catalogoConStock(TipoArticulo.vendibles(), filtroCategoria).stream()
                .map(fila -> aDTO((EspProducto) fila[0], (ArticuloStock) fila[1]))
                .toList();
        TipoArticulo filtroTipo = (tipo != null && !tipo.isBlank()) ? parseTipo(tipo) : null;
        return catalogo.stream()
                .filter(p -> filtroTipo == null || p.tipo() == filtroTipo)
                .filter(p -> vendible == null || esVendibleEnPos(p) == vendible)
                .toList();
    }

    private static boolean esVendibleEnPos(ProductoCatalogoDTO p) {
        return Boolean.TRUE.equals(p.activo()) && p.tipo().seVende() && Boolean.TRUE.equals(p.vendible());
    }

    private static TipoArticulo parseTipo(String tipo) {
        try {
            return TipoArticulo.valueOf(tipo.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ProductoInvalidoException("Tipo de producto no válido: " + tipo);
        }
    }

    /** Desde Productos solo se crea reventa; los elaborados nacen desde Recetas. */
    private static TipoArticulo tipoParaCrear(String tipo) {
        if (tipo == null || tipo.isBlank()) {
            throw new ProductoInvalidoException("El tipo de producto es obligatorio.");
        }
        TipoArticulo t = parseTipo(tipo);
        if (t == TipoArticulo.ELABORADO) {
            throw new ProductoInvalidoException("Los productos elaborados se crean desde Recetas.");
        }
        if (t.esDeMateriaPrima()) {
            throw new ProductoInvalidoException("Los artículos de tipo " + t.name()
                    + " se crean desde Materia Prima.");
        }
        if (t != TipoArticulo.REVENTA) {
            throw new ProductoInvalidoException("El tipo " + t.name() + " todavía no está disponible.");
        }
        return t;
    }

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return getCatalogo(null);
    }

    @Transactional
    public ProductoCatalogoDTO crearProducto(ProductoRequestDTO dto) {
        TipoArticulo tipo = tipoParaCrear(dto.tipo());
        if (dto.stockActual() != null && dto.stockActual() < 0) {
            throw new IllegalArgumentException("El stock no puede ser negativo.");
        }

        BigDecimal costo = dto.precioCosto() != null ? dto.precioCosto() : BigDecimal.ZERO;
        if (costo.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("El precio de costo no puede ser negativo.");
        }

        BigDecimal porcentaje = dto.porcentajeGanancia();
        BigDecimal precioVenta = dto.precioUnitario();

        // Cálculo recíproco según spec 4.2
        if (costo.compareTo(BigDecimal.ZERO) > 0 && porcentaje != null && precioVenta == null) {
            BigDecimal factor = BigDecimal.ONE.add(porcentaje.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP));
            precioVenta = costo.multiply(factor).setScale(2, RoundingMode.HALF_UP);
        } else if (costo.compareTo(BigDecimal.ZERO) > 0 && precioVenta != null && porcentaje == null) {
            porcentaje = precioVenta.subtract(costo)
                    .divide(costo, 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        if (precioVenta == null) {
            throw new IllegalArgumentException("El precio es obligatorio.");
        }

        if (precioVenta.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
        }

        UnidadMedida unidad = UnidadMedida.UNIDAD;
        if (dto.unidadMedida() != null && !dto.unidadMedida().isBlank()) {
            try {
                unidad = UnidadMedida.valueOf(dto.unidadMedida().trim().toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Unidad de medida no válida: " + dto.unidadMedida());
            }
        }
        Categoria categoria = null;
        if (dto.categoriaId() != null) {
            categoria = categoriaRepository.findById(dto.categoriaId()).orElse(null);
        }

        // El código lo genera el sistema (REV-0001, ...); el enviado se ignora.
        EspProducto nuevoProducto = new EspProducto(
                codigoService.siguiente(tipo),
                dto.nombre(),
                precioVenta,
                costo,
                porcentaje,
                unidad,
                categoria
        );

        nuevoProducto.setTipo(tipo);
        if (dto.activo() != null) {
            nuevoProducto.setActivo(dto.activo());
        }
        productoRepository.save(nuevoProducto);

        ArticuloStock nuevoStock = new ArticuloStock(nuevoProducto,
                dto.stockActual() != null ? dto.stockActual() : 0L);
        nuevoStock.setStockMinimo(BigDecimal.valueOf(dto.stockMinimo() != null ? dto.stockMinimo() : 0));
        stockRepository.save(nuevoStock);

        return aDTO(nuevoProducto, nuevoStock);
    }

    @Transactional
    public ProductoCatalogoDTO actualizarProducto(String codigo, ProductoRequestDTO dto) {
        EspProducto productoExistente = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));

        if (dto.tipo() != null && !dto.tipo().isBlank()
                && parseTipo(dto.tipo()) != productoExistente.getTipo()) {
            throw new ProductoInvalidoException("El tipo de un producto no se puede cambiar.");
        }
        if (dto.vendible() != null) {
            if (!dto.vendible() && productoExistente.getTipo() != TipoArticulo.ELABORADO) {
                throw new ProductoInvalidoException("Solo un producto elaborado puede ser preparación base.");
            }
            productoExistente.setVendible(dto.vendible());
        }

        if (dto.nombre() != null) {
            productoExistente.setNombre(dto.nombre());
        }

        if (dto.precioCosto() != null) {
            if (dto.precioCosto().compareTo(BigDecimal.ZERO) < 0) {
                throw new IllegalArgumentException("El precio de costo no puede ser negativo.");
            }
            productoExistente.setPrecioCosto(dto.precioCosto());
        }

        if (dto.porcentajeGanancia() != null) {
            productoExistente.setPorcentajeGanancia(dto.porcentajeGanancia());
            if (dto.precioUnitario() == null && productoExistente.getPrecioCosto().compareTo(BigDecimal.ZERO) > 0) {
                productoExistente.recalcularPrecioDesdeCostoYMargen();
            }
        }

        // Reventa + materia prima: el costo sale de Materia Prima. Un precio
        // distinto del actual queda fijado a mano (no sigue al costo).
        boolean mismoPrecio = dto.precioUnitario() != null && productoExistente.getPrecioUnitario() != null
                && dto.precioUnitario().compareTo(productoExistente.getPrecioUnitario()) == 0;
        if (dto.precioUnitario() != null && !(productoExistente.esReventaMateriaPrima() && mismoPrecio)) {
            if (dto.precioUnitario().compareTo(new BigDecimal("0.01")) < 0) {
                throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
            }
            productoExistente.setPrecioUnitario(dto.precioUnitario());
            if (productoExistente.esReventaMateriaPrima()) {
                productoExistente.setPrecioManual(true);
            }
            if (dto.porcentajeGanancia() == null) {
                productoExistente.recalcularMargenDesdePrecios();
            }
        }

        if (dto.unidadMedida() != null && !dto.unidadMedida().isBlank()) {
            try {
                productoExistente.setUnidadMedida(UnidadMedida.valueOf(dto.unidadMedida().trim().toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Unidad de medida no válida: " + dto.unidadMedida());
            }
        }

        if (dto.categoriaId() != null) {
            Categoria categoria = categoriaRepository.findById(dto.categoriaId()).orElse(null);
            productoExistente.setCategoria(categoria);
        }

        if (dto.activo() != null) {
            productoExistente.setActivo(dto.activo());
        }

        productoRepository.save(productoExistente);

        ArticuloStock stock = stockRepository.findByEspProducto(productoExistente)
                .orElseGet(() -> new ArticuloStock(productoExistente, BigDecimal.ZERO));

        if (dto.stockMinimo() != null) {
            // En unidades de venta (cajas para la reventa + materia prima).
            stock.setStockMinimo(productoExistente.stockParaVender(dto.stockMinimo()));
            stockRepository.save(stock);
        }

        return aDTO(productoExistente, stock);
    }

    /**
     * Ajuste en unidades de venta: unidades para elaborados y reventa; para la
     * reventa + materia prima, unidades de venta enteras (1 caja = 100 g).
     */
    @Transactional
    public ProductoCatalogoDTO ajustarStock(String codigo, Integer cantidad) {
        EspProducto producto = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));

        ArticuloStock stock = stockRepository.findByEspProducto(producto)
                .orElseGet(() -> new ArticuloStock(producto, BigDecimal.ZERO));

        BigDecimal ajuste = producto.stockParaVender(Math.abs(cantidad.longValue()));
        BigDecimal nuevoStock = cantidad < 0 ? stock.getCantidad().subtract(ajuste) : stock.getCantidad().add(ajuste);
        if (nuevoStock.signum() < 0) {
            throw new IllegalArgumentException("El stock no puede quedar negativo.");
        }

        stock.setCantidad(nuevoStock);
        stockRepository.save(stock);

        return aDTO(producto, stock);
    }

    /** Stock y stock mínimo en unidades de venta enteras (cajas para la reventa + materia prima). */
    private static ProductoCatalogoDTO aDTO(EspProducto p, ArticuloStock stock) {
        BigDecimal cantidad = stock != null ? stock.getCantidad() : BigDecimal.ZERO;
        BigDecimal minimo = stock != null ? stock.getStockMinimo() : BigDecimal.ZERO;
        return new ProductoCatalogoDTO(
                p.getCodigo(),
                p.getNombre(),
                p.getPrecioUnitario(),
                p.getPrecioCosto(),
                p.getPorcentajeGanancia(),
                p.getUnidadMedida(),
                p.getCategoria() != null ? p.getCategoria().getNombre() : null,
                p.unidadesDeVentaEn(cantidad),
                (int) p.unidadesDeVentaEn(minimo),
                p.isActivo(),
                p.getTipo(),
                p.isVendible(),
                p.esReventaMateriaPrima() ? p.getVentaUnidadNombre() : null,
                p.isPrecioManual()
        );
    }
}
