package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.CategoriaDuplicadaException;
import com.sgiu_group.sgiu.exceptions.RecursoNoEncontradoException;
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
        return listarCategorias(false);
    }

    /**
     * Por defecto solo las activas (las que se ofrecen en los formularios).
     * Con [incluirInactivas], todas (pantalla de Configuración).
     */
    @Transactional(readOnly = true)
    public List<CategoriaDTO> listarCategorias(boolean incluirInactivas) {
        List<Categoria> categorias = incluirInactivas
                ? categoriaRepository.findAll()
                : categoriaRepository.findByActivoTrue();
        return categorias.stream().map(CategoriaService::aDTO).toList();
    }

    /** Renombra (y actualiza la descripción). No se elimina nada. */
    @Transactional
    public CategoriaDTO actualizarCategoria(Long id, CategoriaDTO dto) {
        Categoria categoria = buscar(id);
        if (dto == null || dto.nombre() == null || dto.nombre().trim().isEmpty()) {
            throw new IllegalArgumentException("El nombre de la categoría es obligatorio.");
        }
        String nombre = dto.nombre().trim();
        categoriaRepository.findByNombre(nombre)
                .filter(otra -> !otra.getId().equals(id))
                .ifPresent(otra -> {
                    throw new CategoriaDuplicadaException("Ya existe una categoría con el nombre: " + nombre);
                });
        categoria.setNombre(nombre);
        categoria.setDescripcion(dto.descripcion());
        return aDTO(categoriaRepository.save(categoria));
    }

    /**
     * Desactiva o reactiva. Una categoría inactiva no se ofrece en los
     * formularios, pero los productos que ya la tienen la conservan.
     */
    @Transactional
    public CategoriaDTO cambiarEstado(Long id, boolean activo) {
        Categoria categoria = buscar(id);
        categoria.setActivo(activo);
        return aDTO(categoriaRepository.save(categoria));
    }

    private Categoria buscar(Long id) {
        return categoriaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Categoría no encontrada con ID: " + id));
    }

    private static CategoriaDTO aDTO(Categoria c) {
        return new CategoriaDTO(c.getId(), c.getNombre(), c.getDescripcion(), c.isActivo());
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
