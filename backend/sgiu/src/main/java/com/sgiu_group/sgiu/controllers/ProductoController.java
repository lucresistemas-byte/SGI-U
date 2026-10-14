package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.models.dtos.ProductoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.StockRequestDTO;
import com.sgiu_group.sgiu.services.ProduccionService;
import com.sgiu_group.sgiu.services.ProductoService;
import com.sgiu_group.sgiu.services.ReintentoStock;
import com.sgiu_group.sgiu.models.dtos.ProduccionRequestDTO;
import com.sgiu_group.sgiu.models.dtos.ProduccionResponseDTO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;
    private final ProduccionService produccionService;
    private final ReintentoStock reintento;

    /**
     * Producir (cargar stock de) un elaborado o un paquete: descuenta sus
     * componentes. 409 FALTAN_COMPONENTES con la lista si algo no alcanza y no
     * se confirmó.
     */
    @PostMapping("/{codigo}/produccion")
    public ResponseEntity<ProduccionResponseDTO> producir(@PathVariable String codigo,
                                                          @Valid @RequestBody ProduccionRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reintento.ejecutar(() -> produccionService.producir(
                codigo, dto.cantidad(), Boolean.TRUE.equals(dto.confirmarFaltantes()), dto.motivo())));
    }

    @GetMapping
    /** Filtros opcionales: categoria, tipo (TipoArticulo) y vendible (true = lo que ve el POS). */
    public ResponseEntity<List<ProductoCatalogoDTO>> listarProductos(
            @RequestParam(required = false) String categoria,
            @RequestParam(required = false) String tipo,
            @RequestParam(required = false) Boolean vendible) {
        return ResponseEntity.ok(productoService.getCatalogo(categoria, tipo, vendible));
    }

    @PostMapping("/crear")
    public ResponseEntity<?> crearProducto(@Valid @RequestBody ProductoRequestDTO dto) {
        try {
            ProductoCatalogoDTO nuevoProducto = productoService.crearProducto(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(nuevoProducto);
        } catch (IllegalArgumentException e) {
            String mensaje = e.getMessage();
            if (mensaje.contains("código") || mensaje.contains("existe")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", mensaje));
            }
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(Map.of("error", mensaje));
        }
    }

    @PutMapping("/editar/{codigo}")
    public ResponseEntity<?> actualizarProducto(
            @PathVariable String codigo,
            @Valid @RequestBody ProductoRequestDTO dto) {
        try {
            ProductoCatalogoDTO productoActualizado = productoService.actualizarProducto(codigo, dto);
            return ResponseEntity.ok(productoActualizado);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/stock/{codigo}")
    public ResponseEntity<?> ajustarStock(
            @PathVariable String codigo,
            @Valid @RequestBody StockRequestDTO request) {
        try {
            ProductoCatalogoDTO resultado = reintento.ejecutar(() ->
                    productoService.ajustarStock(codigo, request.cantidad(), request.motivo(), request.tipo()));
            return ResponseEntity.ok(resultado);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(Map.of("error", e.getMessage()));
        }
    }
}
