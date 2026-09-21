package com.sgiu_group.sgiu.controllers;

import com.sgiu_group.sgiu.models.dtos.AbonoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.PedidoRequestDTO;
import com.sgiu_group.sgiu.models.dtos.PedidoResponseDTO;
import com.sgiu_group.sgiu.services.PedidoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pedidos")
@RequiredArgsConstructor
public class PedidoController {

    private final PedidoService pedidoService;

    @GetMapping
    public ResponseEntity<List<PedidoResponseDTO>> listarOBuscar(@RequestParam(required = false) String q) {
        return ResponseEntity.ok(pedidoService.buscarPedidos(q));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PedidoResponseDTO> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(pedidoService.obtenerPorId(id));
    }

    @PostMapping
    public ResponseEntity<PedidoResponseDTO> crear(@Valid @RequestBody PedidoRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(pedidoService.crearPedido(dto));
    }

    @PostMapping("/{id}/abonar")
    public ResponseEntity<PedidoResponseDTO> abonarSaldo(@PathVariable Long id, @Valid @RequestBody AbonoRequestDTO dto) {
        return ResponseEntity.ok(pedidoService.abonarSaldo(id, dto));
    }

    @PostMapping("/{id}/cancelar")
    public ResponseEntity<PedidoResponseDTO> cancelar(@PathVariable Long id) {
        return ResponseEntity.ok(pedidoService.cancelarPedido(id));
    }
}
