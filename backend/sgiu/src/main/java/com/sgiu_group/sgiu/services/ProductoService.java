package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.CambioPrecioDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.ModoPrecio;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.TipoMovimientoStock;
import com.sgiu_group.sgiu.exceptions.ProductoInvalidoException;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final CodigoService codigoService;
    private final EspProductoRepository productoRepository;
    private final ArticuloStockRepository stockRepository;
    private final CategoriaRepository categoriaRepository;
    private final CostosService costosService;
    private final RecetaRepository recetaRepository;
    private final StockService stockService;
    private final ProduccionService produccionService;

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
                .map(fila -> aDTO((EspProducto) fila[0], (ArticuloStock) fila[1], List.of()))
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
        if (t == TipoArticulo.PAQUETE) {
            throw new ProductoInvalidoException("Los paquetes se crean desde Recetas y paquetes.");
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
        if (precioVenta == null && (porcentaje == null || costo.signum() == 0)) {
            throw new IllegalArgumentException("El precio es obligatorio.");
        }
        if (precioVenta != null && precioVenta.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
        }
        // Con precio, es el de Sandra (MANUAL) salvo que se pida MARGEN; sin
        // precio, sale del %. Lo calcula CostosService.
        boolean manual = esManual(dto.modoPrecio(), precioVenta != null);

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
                BigDecimal.ZERO,
                costo,
                porcentaje,
                unidad,
                categoria
        );

        nuevoProducto.setTipo(tipo);
        if (manual && porcentaje == null) {
            // Sin %, el mínimo es el % que deja el precio de Sandra.
            nuevoProducto.setPorcentajeGanancia(costosService.porcentajeQueDeja(precioVenta, costo));
        }
        costosService.recalcular(nuevoProducto);
        if (manual) {
            costosService.aplicarPrecioManual(nuevoProducto, precioVenta);
        } else if (nuevoProducto.getPrecioUnitario().signum() <= 0) {
            throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
        }
        if (dto.activo() != null) {
            nuevoProducto.setActivo(dto.activo());
        }
        productoRepository.save(nuevoProducto);

        ArticuloStock nuevoStock = new ArticuloStock(nuevoProducto, BigDecimal.ZERO);
        nuevoStock.setStockMinimo(BigDecimal.valueOf(dto.stockMinimo() != null ? dto.stockMinimo() : 0));
        stockRepository.save(nuevoStock);
        if (dto.stockActual() != null && dto.stockActual() > 0) {
            stockService.mover(nuevoStock, TipoMovimientoStock.AJUSTE, BigDecimal.valueOf(dto.stockActual()),
                    "Stock inicial", null, null);
        }

        return aDTO(nuevoProducto, nuevoStock, List.of());
    }

    /** MANUAL si se pidió así o, sin modo, si [porDefecto]. */
    private static boolean esManual(String modo, boolean porDefecto) {
        if (modo == null || modo.isBlank()) {
            return porDefecto;
        }
        try {
            ModoPrecio m = ModoPrecio.valueOf(modo.trim().toUpperCase());
            if (m == ModoPrecio.COSTO_MAS_FIJO) {
                throw new ProductoInvalidoException("El modo costo + monto fijo es solo para paquetes.");
            }
            return m == ModoPrecio.MANUAL;
        } catch (IllegalArgumentException e) {
            throw new ProductoInvalidoException("Modo de precio no válido: " + modo + ". Use MARGEN o MANUAL.");
        }
    }

    @Transactional
    public ProductoCatalogoDTO actualizarProducto(String codigo, ProductoRequestDTO dto) {
        EspProducto productoExistente = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));
        CostosService.Foto antes = costosService.foto(productoExistente);

        if (dto.tipo() != null && !dto.tipo().isBlank()
                && parseTipo(dto.tipo()) != productoExistente.getTipo()) {
            throw new ProductoInvalidoException("El tipo de un producto no se puede cambiar.");
        }
        if (dto.vendible() != null) {
            if (!dto.vendible() && productoExistente.getTipo() != TipoArticulo.ELABORADO) {
                throw new ProductoInvalidoException("Solo un producto elaborado puede ser preparación base.");
            }
            if (dto.vendible() && productoExistente.esPreparacionBase()) {
                List<String> recetas = recetaRepository.findRecetasByArticuloId(productoExistente.getId()).stream()
                        .map(r -> r.getNombre()).toList();
                if (!recetas.isEmpty()) {
                    throw new ProductoInvalidoException(productoExistente.getNombre()
                            + " se usa como preparación base en recetas activas (" + String.join(", ", recetas)
                            + "): quítela de esas recetas antes de venderla.");
                }
            }
            productoExistente.setVendible(dto.vendible());
        }

        if (dto.nombre() != null) {
            productoExistente.setNombre(dto.nombre());
        }

        // Precios: el paquete se edita en Recetas y paquetes; el costo de
        // elaborados y reventa + materia prima lo calcula CostosService.
        if (productoExistente.getTipo() != TipoArticulo.PAQUETE) {
            aplicarPrecio(productoExistente, dto);
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
        List<CambioPrecioDTO> cambios = costosService.propagar(productoExistente, antes,
                "Cambio en " + productoExistente.getNombre() + " (" + productoExistente.getCodigo() + ")");

        ArticuloStock stock = stockRepository.findByEspProducto(productoExistente)
                .orElseGet(() -> new ArticuloStock(productoExistente, BigDecimal.ZERO));

        if (dto.stockMinimo() != null) {
            // En unidades de venta (cajas para la reventa + materia prima).
            stock.setStockMinimo(productoExistente.stockParaVender(dto.stockMinimo()));
            stockRepository.save(stock);
        }

        return aDTO(productoExistente, stock, cambios);
    }

    /**
     * Costo (solo reventa: lo carga Sandra), % de ganancia y modo. Un precio
     * distinto del actual (o con modo MANUAL) queda fijado a mano, siempre que
     * deje el %; con modo MARGEN el precio vuelve a seguir al costo.
     */
    private void aplicarPrecio(EspProducto p, ProductoRequestDTO dto) {
        if (dto.precioCosto() != null && p.getTipo() == TipoArticulo.REVENTA) {
            if (dto.precioCosto().compareTo(BigDecimal.ZERO) < 0) {
                throw new IllegalArgumentException("El precio de costo no puede ser negativo.");
            }
            p.setPrecioCosto(dto.precioCosto());
        }
        if (dto.porcentajeGanancia() != null) {
            p.setPorcentajeGanancia(dto.porcentajeGanancia());
        }
        if (dto.precioUnitario() != null && dto.precioUnitario().compareTo(new BigDecimal("0.01")) < 0) {
            throw new IllegalArgumentException("El precio debe ser un valor mayor a $0.");
        }
        boolean otroPrecio = dto.precioUnitario() != null
                && (p.getPrecioUnitario() == null || dto.precioUnitario().compareTo(p.getPrecioUnitario()) != 0);
        if (dto.modoPrecio() != null && !esManual(dto.modoPrecio(), false)) {
            p.setModoPrecio(ModoPrecio.MARGEN);
        } else if (dto.precioUnitario() != null && (otroPrecio || esManual(dto.modoPrecio(), false))) {
            costosService.recalcular(p);
            costosService.aplicarPrecioManual(p, dto.precioUnitario());
        }
    }

    /**
     * Ajuste manual en unidades de venta: unidades para elaborados y reventa;
     * para la reventa + materia prima, unidades de venta enteras (1 caja =
     * 100 g). Deja un movimiento (COMPRA, AJUSTE o MERMA) con el motivo. Un
     * elaborado o un paquete suma stock produciendo (descuenta sus
     * componentes), salvo una corrección explícita (AJUSTE).
     */
    @Transactional
    public ProductoCatalogoDTO ajustarStock(String codigo, Integer cantidad, String motivo, String tipo) {
        EspProducto producto = productoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("No se encontró un producto con el código: " + codigo));
        if (cantidad == 0) {
            throw new IllegalArgumentException("Indique una cantidad distinta de 0.");
        }
        TipoMovimientoStock tipoMovimiento = StockService.tipoDeAjuste(tipo, cantidad);
        boolean seProduce = producto.getTipo() == TipoArticulo.PAQUETE
                || producto.getTipo() == TipoArticulo.ELABORADO;
        if (seProduce && cantidad > 0 && tipoMovimiento != TipoMovimientoStock.AJUSTE) {
            throw new ProductoInvalidoException("Para sumar stock de " + producto.getNombre()
                    + " use Producir: descuenta sus ingredientes o insumos.");
        }

        ArticuloStock stock = stockRepository.findByEspProducto(producto)
                .orElseGet(() -> new ArticuloStock(producto, BigDecimal.ZERO));
        BigDecimal ajuste = producto.stockParaVender(Math.abs(cantidad.longValue()));
        if (cantidad < 0 && stock.getCantidad().subtract(ajuste).signum() < 0) {
            throw new IllegalArgumentException("El stock no puede quedar negativo.");
        }
        stockService.mover(stock, tipoMovimiento, cantidad < 0 ? ajuste.negate() : ajuste, motivo, null, null);

        return aDTO(producto, stock, List.of());
    }

    /** Stock y stock mínimo en unidades de venta enteras (cajas para la reventa + materia prima). */
    private ProductoCatalogoDTO aDTO(EspProducto p, ArticuloStock stock, List<CambioPrecioDTO> cambios) {
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
                p.getModoPrecio().name(),
                p.esPreparacionBase() ? null : CostosService.ganancia(p.getPrecioUnitario(), p.getPrecioCosto()),
                p.getMontoFijo(),
                cambios,
                produccionService.puedeProducir(p)
        );
    }
}
