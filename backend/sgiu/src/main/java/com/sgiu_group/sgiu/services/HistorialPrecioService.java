package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.FechasInvalidasException;
import com.sgiu_group.sgiu.models.dtos.HistorialPrecioDTO;
import com.sgiu_group.sgiu.repositories.HistorialPrecioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class HistorialPrecioService {

    private final HistorialPrecioRepository historialRepository;

    /** Sin fechas: los últimos 30 días. [hasta] incluye todo ese día. */
    @Transactional(readOnly = true)
    public List<HistorialPrecioDTO> buscar(LocalDate desde, LocalDate hasta, String codigo) {
        LocalDate fin = hasta != null ? hasta : LocalDate.now();
        LocalDate inicio = desde != null ? desde : fin.minusDays(30);
        if (inicio.isAfter(fin)) {
            throw new FechasInvalidasException("La fecha desde no puede ser posterior a la fecha hasta.");
        }
        String filtro = codigo != null && !codigo.isBlank() ? codigo.trim() : null;
        return historialRepository.buscar(inicio.atStartOfDay(), fin.plusDays(1).atStartOfDay(), filtro).stream()
                .map(h -> new HistorialPrecioDTO(
                        h.getId(),
                        h.getFecha(),
                        h.getArticulo().getCodigo(),
                        h.getArticulo().getNombre(),
                        h.getArticulo().getTipo().name(),
                        h.getCostoAnterior(),
                        h.getCostoNuevo(),
                        h.getPrecioAnterior(),
                        h.getPrecioNuevo(),
                        h.getModoPrecio().name(),
                        h.getCausa(),
                        h.getUsuario()))
                .toList();
    }
}
