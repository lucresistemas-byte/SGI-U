package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.MetodoPagoDuplicadoException;
import com.sgiu_group.sgiu.exceptions.MetodoPagoInvalidoException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
import com.sgiu_group.sgiu.models.dtos.MetodoPagoDTO;
import com.sgiu_group.sgiu.models.entities.MetodoPago;
import com.sgiu_group.sgiu.repositories.MetodoPagoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Métodos de pago configurables. No se borran: se desactivan (los registros
 * históricos los siguen mostrando). "Efectivo" (fijo) no se renombra ni se
 * desactiva.
 */
@Service
@RequiredArgsConstructor
public class MetodoPagoService {

    private final MetodoPagoRepository repository;

    /** Por defecto solo los activos (los que se ofrecen); con [incluirInactivos], todos. */
    @Transactional(readOnly = true)
    public List<MetodoPagoDTO> listar(boolean incluirInactivos) {
        List<MetodoPago> metodos = incluirInactivos
                ? repository.findAllByOrderByOrdenAscIdAsc()
                : repository.findByActivoTrueOrderByOrdenAscIdAsc();
        return metodos.stream().map(MetodoPagoDTO::de).toList();
    }

    @Transactional
    public MetodoPagoDTO crear(String nombre) {
        String limpio = validarNombre(nombre, null);
        MetodoPago metodo = new MetodoPago(limpio, false, repository.maxOrden() + 1);
        return MetodoPagoDTO.de(repository.save(metodo));
    }

    @Transactional
    public MetodoPagoDTO renombrar(Long id, String nombre) {
        MetodoPago metodo = buscar(id);
        if (metodo.isFijo()) {
            throw new MetodoPagoInvalidoException(metodo.getNombre() + " no se puede renombrar.");
        }
        metodo.setNombre(validarNombre(nombre, id));
        return MetodoPagoDTO.de(repository.save(metodo));
    }

    @Transactional
    public MetodoPagoDTO cambiarEstado(Long id, boolean activo) {
        MetodoPago metodo = buscar(id);
        if (metodo.isFijo() && !activo) {
            throw new MetodoPagoInvalidoException(metodo.getNombre() + " no se puede desactivar.");
        }
        metodo.setActivo(activo);
        return MetodoPagoDTO.de(repository.save(metodo));
    }

    /** Recibe todos los métodos en el orden nuevo. */
    @Transactional
    public List<MetodoPagoDTO> reordenar(List<Long> ids) {
        List<MetodoPago> todos = repository.findAll();
        if (ids.size() != todos.size() || !new HashSet<>(ids).equals(
                todos.stream().map(MetodoPago::getId).collect(Collectors.toSet()))) {
            throw new MetodoPagoInvalidoException("Para reordenar envíe todos los métodos de pago, una vez cada uno.");
        }
        Map<Long, MetodoPago> porId = todos.stream().collect(Collectors.toMap(MetodoPago::getId, Function.identity()));
        for (int i = 0; i < ids.size(); i++) {
            porId.get(ids.get(i)).setOrden(i + 1);
        }
        repository.saveAll(todos);
        return listar(true);
    }

    /** Método para un cobro nuevo: tiene que existir y estar activo. */
    @Transactional(readOnly = true)
    public MetodoPago paraCobrar(Long id) {
        if (id == null) {
            throw new MetodoPagoInvalidoException("Indique el método de pago.");
        }
        MetodoPago metodo = repository.findById(id)
                .orElseThrow(() -> new MetodoPagoInvalidoException("El método de pago " + id + " no existe."));
        if (!metodo.isActivo()) {
            throw new MetodoPagoInvalidoException("El método de pago " + metodo.getNombre() + " está desactivado.");
        }
        return metodo;
    }

    /** Efectivo: el método por defecto cuando no se indica otro. */
    @Transactional(readOnly = true)
    public MetodoPago efectivo() {
        return repository.findFirstByFijoTrue()
                .orElseThrow(() -> new IllegalStateException("Falta el método de pago Efectivo."));
    }

    private MetodoPago buscar(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Método de pago no encontrado con ID: " + id));
    }

    private String validarNombre(String nombre, Long idActual) {
        if (nombre == null || nombre.isBlank()) {
            throw new MetodoPagoInvalidoException("El nombre del método de pago es obligatorio.");
        }
        String limpio = nombre.trim();
        repository.findByNombreIgnoreCase(limpio)
                .filter(otro -> !otro.getId().equals(idActual))
                .ifPresent(otro -> {
                    throw new MetodoPagoDuplicadoException("Ya existe el método de pago " + otro.getNombre() + ".");
                });
        return limpio;
    }
}
