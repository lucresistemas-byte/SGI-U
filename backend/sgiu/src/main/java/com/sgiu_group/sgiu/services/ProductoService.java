package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.dtos.ProductoCatalogoDTO;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final EspProductoRepository productoRepository;

    @Transactional(readOnly = true)
    public List<ProductoCatalogoDTO> getCatalogo() {
        return productoRepository.obtenerCatalogo();
    }
}