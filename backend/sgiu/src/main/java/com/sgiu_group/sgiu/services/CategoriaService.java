package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.CategoriaDuplicadaException;
import com.sgiu_group.sgiu.models.dtos.CategoriaDTO;
import com.sgiu_group.sgiu.models.entities.Categoria;
import com.sgiu_group.sgiu.repositories.CategoriaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;

    @Transactional(readOnly = true)
    public List<CategoriaDTO> listarCategorias() {
        return categoriaRepository.findAll().stream()
                .map(c -> new CategoriaDTO(c.getId(), c.getNombre(), c.getDescripcion(), c.isActivo()))
                .toList();
    }

    @Transactional
    public CategoriaDTO crearCategoria(CategoriaDTO dto) {
        if (dto == null || dto.nombre() == null || dto.nombre().trim().isEmpty()) {
            throw new IllegalArgumentException("El nombre de la categoría es obligatorio.");
        }
        String nombreNormalizado = dto.nombre().trim();
        if (categoriaRepository.existsByNombre(nombreNormalizado)) {
            throw new CategoriaDuplicadaException("Ya existe una categoría con el nombre: " + nombreNormalizado);
        }

        Categoria categoria = new Categoria(nombreNormalizado, dto.descripcion());
        if (dto.activo() != null) {
            categoria.setActivo(dto.activo());
        }
        Categoria guardada = categoriaRepository.save(categoria);

        return new CategoriaDTO(guardada.getId(), guardada.getNombre(), guardada.getDescripcion(), guardada.isActivo());
    }
}
