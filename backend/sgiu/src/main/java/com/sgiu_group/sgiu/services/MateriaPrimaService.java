package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.RecetaInvalidaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.AjusteStockMateriaPrimaDTO;
import com.sgiu_group.sgiu.models.dtos.CambioPrecioDTO;
import com.sgiu_group.sgiu.models.dtos.MateriaPrimaRequestDTO;
import com.sgiu_group.sgiu.models.dtos.MateriaPrimaResponseDTO;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.models.entities.FamiliaUnidad;
import com.sgiu_group.sgiu.models.entities.ModoPrecio;
import com.sgiu_group.sgiu.models.entities.Receta;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.models.entities.UnidadMedida;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Artículos de Materia Prima: materia prima, insumo y reventa + materia prima.
 * Son filas de esp_productos; su stock (articulos_stock) y su costo se guardan
 * en la unidad base de su familia.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MateriaPrimaService {

    /** Unidad de stock: la presentación de compra ("llegó 1 bulto"). */
    public static final String PRESENTACION = "PRESENTACION";
    /** Unidad de stock: la unidad de venta de la reventa + materia prima ("3 cajas"). */
    public static final String UNIDAD_VENTA = "UNIDAD_VENTA";

    private final EspProductoRepository productoRepository;
    private final ArticuloStockRepository stockRepository;
    private final RecetaRepository recetaRepository;
    private final CategoriaRepository categoriaRepository;
    private final CodigoService codigoService;
    private final CostosService costosService;

    @Transactional(readOnly = true)
    public List<MateriaPrimaResponseDTO> listarTodos(boolean incluirInactivos) {
        List<EspProducto> articulos = incluirInactivos
                ? productoRepository.findByTipoIn(TipoArticulo.deMateriaPrima())
                : productoRepository.findByTipoInAndActivoTrue(TipoArticulo.deMateriaPrima());
        Map<Long, ArticuloStock> stocks = stockRepository.findByEspProductoIn(articulos).stream()
                .collect(Collectors.toMap(s -> s.getEspProducto().getId(), Function.identity()));
        return articulos.stream()
                .sorted(Comparator.comparing(EspProducto::getCodigo))
                .map(a -> toResponseDTO(a, stocks.get(a.getId())))
                .toList();
    }

    /** Componentes de receta activos: los de Materia Prima y las preparaciones base con rinde en peso o volumen. */
    @Transactional(readOnly = true)
    public List<MateriaPrimaResponseDTO> listarComponentesDeReceta() {
        List<EspProducto> articulos = new ArrayList<>(
                productoRepository.findByTipoInAndActivoTrue(TipoArticulo.deMateriaPrima()));
        productoRepository.findByTipoInAndActivoTrue(java.util.Set.of(TipoArticulo.ELABORADO)).stream()
                .filter(p -> p.esPreparacionBase() && p.getFamilia() != null)
                .forEach(articulos::add);
        Map<Long, ArticuloStock> stocks = stockRepository.findByEspProductoIn(articulos).stream()
                .collect(Collectors.toMap(s -> s.getEspProducto().getId(), Function.identity()));
        return articulos.stream()
                .sorted(Comparator.comparing(EspProducto::getNombre, String.CASE_INSENSITIVE_ORDER))
                .map(a -> toResponseDTO(a, stocks.get(a.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public MateriaPrimaResponseDTO obtenerPorId(Long id) {
        EspProducto articulo = buscar(id);
        return toResponseDTO(articulo, stockDe(articulo));
    }

    @Transactional
    public MateriaPrimaResponseDTO crear(MateriaPrimaRequestDTO dto) {
        TipoArticulo tipo = parseTipo(dto.tipo());
        UnidadMedida unidad = parseUnidad(dto.unidadMedida());
        EspProducto articulo = new EspProducto();
        articulo.setCodigo(codigoService.siguiente(tipo));
        articulo.setTipo(tipo);
        articulo.setNombre(dto.nombre().trim());
        articulo.setFamilia(unidad.getFamilia());
        articulo.setUnidadMedida(unidad);
        articulo.setPrecioUnitario(BigDecimal.ZERO);
        aplicarPresentacion(articulo, dto);
        aplicarVenta(articulo, dto);
        articulo = productoRepository.save(articulo);
        costosService.propagar(articulo, null, "Alta de " + articulo.getNombre());

        ArticuloStock stock = new ArticuloStock(articulo, cantidadEnBase(articulo, dto.stockActual(), dto.stockUnidad()));
        stock.setStockMinimo(cantidadEnBase(articulo, dto.stockMinimo(), dto.stockUnidad()));
        stock = stockRepository.save(stock);

        log.info("[MATERIA PRIMA] Creado '{}' ({}) con costo ${} por {}", articulo.getNombre(),
                articulo.getCodigo(), articulo.getCostoUnidadBase(), articulo.getFamilia().getUnidadBase());
        return toResponseDTO(articulo, stock, List.of());
    }

    @Transactional
    public MateriaPrimaResponseDTO actualizar(Long id, MateriaPrimaRequestDTO dto) {
        EspProducto articulo = buscar(id);
        ArticuloStock stock = stockDe(articulo);

        CostosService.Foto antes = costosService.foto(articulo);
        articulo.setNombre(dto.nombre().trim());
        UnidadMedida nueva = parseUnidad(dto.unidadMedida());
        if (nueva.getFamilia() != articulo.getFamilia()) {
            validarCambioDeFamilia(articulo, stock, nueva);
            articulo.setFamilia(nueva.getFamilia());
        }
        // Dentro de la misma familia la unidad para mostrar se cambia libremente.
        articulo.setUnidadMedida(nueva);
        aplicarPresentacion(articulo, dto);
        aplicarVenta(articulo, dto);
        if (dto.stockMinimo() != null) {
            stock.setStockMinimo(cantidadEnBase(articulo, dto.stockMinimo(), dto.stockUnidad()));
            stockRepository.save(stock);
        }

        EspProducto actualizado = productoRepository.save(articulo);

        // Se recalculan su costo y precio y, en cascada, todo lo que lo usa
        // (recetas en varios niveles y paquetes).
        List<CambioPrecioDTO> cambios = costosService.propagar(actualizado, antes,
                "Cambio en " + actualizado.getNombre() + " (" + actualizado.getCodigo() + ")");

        return toResponseDTO(actualizado, stock, cambios);
    }

    @Transactional
    public MateriaPrimaResponseDTO ajustarStock(Long id, AjusteStockMateriaPrimaDTO dto) {
        EspProducto articulo = buscar(id);
        ArticuloStock stock = stockDe(articulo);

        String unidad = dto.unidad() == null || dto.unidad().isBlank()
                ? articulo.getUnidadMedida().name() : dto.unidad();
        BigDecimal ajusteBase = cantidadEnBase(articulo, dto.cantidad(), unidad);
        BigDecimal nuevoStock = stock.getCantidad().add(ajusteBase);
        UnidadMedida base = articulo.getFamilia().getUnidadBase();
        if (nuevoStock.signum() < 0) {
            throw new RecetaInvalidaException("El stock resultante no puede ser negativo (actual: "
                    + articulo.getUnidadMedida().texto(stock.getCantidad()) + ", ajuste: "
                    + articulo.getUnidadMedida().texto(ajusteBase) + ").");
        }

        stock.setCantidad(nuevoStock);
        stock = stockRepository.save(stock);
        log.info("[MATERIA PRIMA] Ajuste de stock para '{}': {}. Motivo: {}. Stock actual: {}",
                articulo.getNombre(), base.texto(ajusteBase), dto.motivo(),
                articulo.getUnidadMedida().texto(stock.getCantidad()));

        return toResponseDTO(articulo, stock);
    }

    /** Activa o desactiva el artículo (no se eliminan). */
    @Transactional
    public MateriaPrimaResponseDTO cambiarEstado(Long id, boolean activo) {
        EspProducto articulo = buscar(id);
        articulo.setActivo(activo);
        log.info("[MATERIA PRIMA] '{}' {}", articulo.getNombre(), activo ? "activado" : "desactivado");
        return toResponseDTO(productoRepository.save(articulo), stockDe(articulo));
    }

    private EspProducto buscar(Long id) {
        return productoRepository.findById(id)
                .filter(a -> a.getTipo().esDeMateriaPrima())
                .orElseThrow(() -> new RecursoNoEncontradoException("Materia prima no encontrada con ID: " + id));
    }

    private ArticuloStock stockDe(EspProducto articulo) {
        return stockRepository.findByEspProducto(articulo)
                .orElseGet(() -> stockRepository.save(new ArticuloStock(articulo, BigDecimal.ZERO)));
    }

    /** Presentación de compra; el costo por unidad base lo calcula CostosService. */
    private void aplicarPresentacion(EspProducto articulo, MateriaPrimaRequestDTO dto) {
        UnidadMedida unidad = unidadDeLaFamilia(articulo, dto.presentacionUnidad(), null);
        articulo.setPresentacionDescripcion(textoOpcional(dto.presentacionDescripcion()));
        articulo.setPresentacionCantidad(dto.presentacionCantidad());
        articulo.setPresentacionUnidad(unidad);
        articulo.setPresentacionPrecio(dto.presentacionPrecio());
        costosService.recalcular(articulo);
    }

    /**
     * Reventa + materia prima: unidad de venta (por defecto, la presentación
     * de compra), % de ganancia, precio a mano opcional (nunca por debajo del
     * %) y categoría. Costo y precio los calcula CostosService.
     */
    private void aplicarVenta(EspProducto articulo, MateriaPrimaRequestDTO dto) {
        if (!articulo.esReventaMateriaPrima()) {
            return;
        }
        BigDecimal contenido = dto.ventaUnidadCantidad() == null
                ? articulo.presentacionEnBase()
                : unidadDeLaFamilia(articulo, dto.ventaUnidadUnidad(), articulo.getUnidadMedida())
                        .aBase(dto.ventaUnidadCantidad());
        String nombre = textoOpcional(dto.ventaUnidadNombre());
        if (nombre == null) {
            nombre = articulo.getPresentacionDescripcion() != null ? articulo.getPresentacionDescripcion() : "Unidad";
        }
        articulo.setVentaUnidadNombre(nombre.length() > 50 ? nombre.substring(0, 50) : nombre);
        articulo.setVentaUnidadContenido(contenido.setScale(3, RoundingMode.HALF_UP));
        articulo.setPorcentajeGanancia(dto.porcentajeGanancia());
        if (dto.categoriaId() != null) {
            Categoria categoria = categoriaRepository.findById(dto.categoriaId())
                    .orElseThrow(() -> new RecetaInvalidaException("La categoría elegida no existe."));
            articulo.setCategoria(categoria);
        }
        articulo.setModoPrecio(ModoPrecio.MARGEN);
        costosService.recalcular(articulo);
        if (dto.precioVenta() != null) {
            costosService.aplicarPrecioManual(articulo, dto.precioVenta());
        }
    }

    /**
     * Cantidad en unidad base. La unidad puede ser una de la familia,
     * PRESENTACION (1 bulto de 12 cajas de 100 g = 1200 g) o UNIDAD_VENTA
     * (1 caja = 100 g); sin unidad, la unidad para mostrar.
     */
    private BigDecimal cantidadEnBase(EspProducto articulo, BigDecimal cantidad, String unidad) {
        if (cantidad == null) {
            return BigDecimal.ZERO;
        }
        BigDecimal base;
        if (PRESENTACION.equalsIgnoreCase(trim(unidad))) {
            base = cantidad.multiply(articulo.presentacionEnBase());
        } else if (UNIDAD_VENTA.equalsIgnoreCase(trim(unidad))) {
            if (!articulo.esReventaMateriaPrima()) {
                throw new RecetaInvalidaException(articulo.getNombre() + " no tiene unidad de venta.");
            }
            base = articulo.stockParaVender(1).multiply(cantidad);
        } else {
            base = unidadDeLaFamilia(articulo, unidad, articulo.getUnidadMedida()).aBase(cantidad);
        }
        return base.setScale(3, RoundingMode.HALF_UP);
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }

    private static String textoOpcional(String s) {
        return s != null && !s.isBlank() ? s.trim() : null;
    }

    /** Unidad indicada (o la de reserva), que tiene que ser de la familia del artículo. */
    private UnidadMedida unidadDeLaFamilia(EspProducto articulo, String unidadStr, UnidadMedida porDefecto) {
        UnidadMedida unidad = unidadStr == null || unidadStr.isBlank() ? porDefecto : parseUnidad(unidadStr);
        if (unidad == null) {
            throw new RecetaInvalidaException("Indique la unidad.");
        }
        if (!unidad.esDe(articulo.getFamilia())) {
            throw new RecetaInvalidaException("La unidad " + unidad.name().toLowerCase() + " no corresponde a "
                    + articulo.getNombre() + ", que se mide en " + articulo.getFamilia().getDescripcion() + " ("
                    + nombres(articulo.getFamilia()) + ").");
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
     * stock o recetas activas que lo usan: no se pueden convertir entre familias.
     */
    private void validarCambioDeFamilia(EspProducto articulo, ArticuloStock stock, UnidadMedida nueva) {
        List<String> motivos = new ArrayList<>();
        if (stock.getCantidad().signum() > 0) {
            motivos.add("tiene stock (" + articulo.getUnidadMedida().texto(stock.getCantidad()) + ")");
        }
        List<String> recetas = recetaRepository.findRecetasByArticuloId(articulo.getId()).stream()
                .map(Receta::getNombre)
                .toList();
        if (!recetas.isEmpty()) {
            motivos.add("se usa en recetas activas (" + String.join(", ", recetas) + ")");
        }
        if (!motivos.isEmpty()) {
            throw new RecetaInvalidaException("No se puede pasar " + articulo.getNombre() + " de "
                    + articulo.getFamilia().getDescripcion() + " a " + nueva.getFamilia().getDescripcion()
                    + " porque " + String.join(" y ", motivos) + ". Lleve el stock a 0 con un ajuste "
                    + "o cree un artículo nuevo.");
        }
    }

    /** Unidad de una familia (CAJA es solo de productos). */
    private static UnidadMedida parseUnidad(String unidadStr) {
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

    public MateriaPrimaResponseDTO toResponseDTO(EspProducto a, ArticuloStock stock) {
        return toResponseDTO(a, stock, List.of());
    }

    public MateriaPrimaResponseDTO toResponseDTO(EspProducto a, ArticuloStock stock, List<CambioPrecioDTO> cambios) {
        BigDecimal cantidad = stock != null ? stock.getCantidad() : BigDecimal.ZERO;
        boolean rmp = a.esReventaMateriaPrima();
        return new MateriaPrimaResponseDTO(
                a.getId(),
                a.getCodigo(),
                a.getTipo().name(),
                a.getNombre(),
                a.getFamilia().name(),
                a.getUnidadMedida().name(),
                a.getFamilia().getUnidadBase().name(),
                a.getCostoUnidadBase(),
                costosService.costoPor(a, a.getUnidadMedida()),
                a.getPresentacionDescripcion(),
                a.getPresentacionCantidad(),
                a.getPresentacionUnidad() != null ? a.getPresentacionUnidad().name() : null,
                a.getPresentacionPrecio(),
                cantidad,
                stock != null ? stock.getStockMinimo() : BigDecimal.ZERO,
                a.isActivo(),
                rmp ? a.getVentaUnidadNombre() : null,
                rmp ? a.getVentaUnidadContenido() : null,
                rmp ? a.unidadesDeVentaEn(cantidad) : null,
                rmp ? a.sueltoEn(cantidad) : null,
                rmp ? a.getPrecioCosto() : null,
                rmp ? a.getPorcentajeGanancia() : null,
                rmp ? a.getPrecioUnitario() : null,
                rmp ? a.getModoPrecio().name() : null,
                rmp ? CostosService.ganancia(a.getPrecioUnitario(), a.getPrecioCosto()) : null,
                a.getCategoria() != null ? a.getCategoria().getId() : null,
                cambios
        );
    }
}
