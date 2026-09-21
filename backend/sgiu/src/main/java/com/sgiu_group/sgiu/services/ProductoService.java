package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
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

    private final EspProductoRepository productoRepository;
    private final ArticuloStockRepository stockRepository;
    private final CategoriaRepository categoriaRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo(String categoria) {
        if (categoria != null && !categoria.isBlank()) {
            return productoRepository.obtenerCatalogoPorCategoria(categoria.trim());
        }
        return productoRepository.obtenerCatalogo();
    }

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return getCatalogo(null);
    }

    @Transactional
    public ProductoCatalogoDTO crearProducto(ProductoRequestDTO dto) {
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

        if (productoRepository.existsByCodigo(dto.codigo())) {
            throw new IllegalArgumentException("El código de producto ya existe.");
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

        EspProducto nuevoProducto = new EspProducto(
                dto.codigo(),
                dto.nombre(),
                precioVenta,
                costo,
                porcentaje,
                unidad,
                categoria
        );

        if (dto.activo() != null) {
            nuevoProducto.setActivo(dto.activo());
        }
        productoRepository.save(nuevoProducto);

        ArticuloStock nuevoStock = new ArticuloStock();
        nuevoStock.setEspProducto(nuevoProducto);
        nuevoStock.setCantidad(dto.stockActual() != null ? dto.stockActual().intValue() : 0);
        nuevoStock.setStockMinimo(dto.stockMinimo() != null ? dto.stockMinimo() : 0);
        stockRepository.save(nuevoStock);

        return new ProductoCatalogoDTO(
                nuevoProducto.getCodigo(),
                nuevoProducto.getNombre(),
                nuevoProducto.getPrecioUnitario(),
                nuevoProducto.getPrecioCosto(),
                nuevoProducto.getPorcentajeGanancia(),
                nuevoProducto.getUnidadMedida(),
                nuevoProducto.getCategoria() != null ? nuevoProducto.getCategoria().getNombre() : null,
                Long.valueOf(nuevoStock.getCantidad()),
                nuevoStock.getStockMinimo(),
                nuevoProducto.isActivo()
        );
    }

    @Transactional
    public ProductoCatalogoDTO actualizarProducto(String codigo, ProductoRequestDTO dto) {
        EspProducto productoExistente = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));

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

        if (dto.precioUnitario() != null) {
            if (dto.precioUnitario().compareTo(new BigDecimal("0.01")) < 0) {
                throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
            }
            productoExistente.setPrecioUnitario(dto.precioUnitario());
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
                .orElseGet(() -> {
                    ArticuloStock nuevo = new ArticuloStock();
                    nuevo.setEspProducto(productoExistente);
                    nuevo.setCantidad(0);
                    nuevo.setStockMinimo(0);
                    return nuevo;
                });

        if (dto.stockMinimo() != null) {
            stock.setStockMinimo(dto.stockMinimo());
            stockRepository.save(stock);
        }

        return new ProductoCatalogoDTO(
                productoExistente.getCodigo(),
                productoExistente.getNombre(),
                productoExistente.getPrecioUnitario(),
                productoExistente.getPrecioCosto(),
                productoExistente.getPorcentajeGanancia(),
                productoExistente.getUnidadMedida(),
                productoExistente.getCategoria() != null ? productoExistente.getCategoria().getNombre() : null,
                Long.valueOf(stock.getCantidad()),
                stock.getStockMinimo(),
                productoExistente.isActivo()
        );
    }

    @Transactional
    public ProductoCatalogoDTO ajustarStock(String codigo, Integer cantidad) {
        EspProducto producto = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));

        ArticuloStock stock = stockRepository.findByEspProducto(producto)
                .orElseGet(() -> {
                    ArticuloStock nuevo = new ArticuloStock();
                    nuevo.setEspProducto(producto);
                    nuevo.setCantidad(0);
                    return nuevo;
                });

        int nuevoStock = stock.getCantidad() + cantidad;
        if (nuevoStock < 0) {
            throw new IllegalArgumentException("El stock no puede quedar negativo.");
        }

        stock.setCantidad(nuevoStock);
        stockRepository.save(stock);

        return new ProductoCatalogoDTO(
                producto.getCodigo(),
                producto.getNombre(),
                producto.getPrecioUnitario(),
                producto.getPrecioCosto(),
                producto.getPorcentajeGanancia(),
                producto.getUnidadMedida(),
                producto.getCategoria() != null ? producto.getCategoria().getNombre() : null,
                Long.valueOf(nuevoStock),
                stock.getStockMinimo(),
                producto.isActivo()
        );
    }
}