package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.models.entities.SecuenciaCodigo;
import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.repositories.MateriaPrimaRepository;
import com.sgiu_group.sgiu.repositories.SecuenciaCodigoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Códigos de artículo generados por el sistema: prefijo según el tipo y
 * cuatro dígitos (ELA-0001, REV-0001, MP-0001, INS-0001, RMP-0001, PAQ-0001).
 * El usuario nunca los escribe.
 */
@Service
@RequiredArgsConstructor
public class CodigoService {

    private final SecuenciaCodigoRepository secuencias;
    private final EspProductoRepository productos;
    private final MateriaPrimaRepository materiasPrimas;
    private final PlatformTransactionManager transactionManager;

    /**
     * Se llama dentro de la transacción que guarda el artículo: la fila de la
     * secuencia queda bloqueada hasta el commit, así dos altas simultáneas no
     * reciben el mismo código; si la transacción falla, el número se libera.
     * Se saltean los códigos que ya existan (cargados a mano o de otra forma).
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public String siguiente(TipoArticulo tipo) {
        String prefijo = tipo.getPrefijo();
        SecuenciaCodigo secuencia = secuencias.bloquear(prefijo).orElseGet(() -> crearYBloquear(prefijo));
        String codigo;
        do {
            secuencia.setUltimo(secuencia.getUltimo() + 1);
            codigo = String.format("%s-%04d", prefijo, secuencia.getUltimo());
        } while (productos.existsByCodigo(codigo) || materiasPrimas.existsByCodigo(codigo));
        return codigo;
    }

    /** La migración crea las filas; esto cubre una base sin ellas (p. ej. los tests en H2). */
    private SecuenciaCodigo crearYBloquear(String prefijo) {
        TransactionTemplate nueva = new TransactionTemplate(transactionManager);
        nueva.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        try {
            nueva.executeWithoutResult(estado -> {
                if (!secuencias.existsById(prefijo)) {
                    secuencias.saveAndFlush(new SecuenciaCodigo(prefijo, 0));
                }
            });
        } catch (DataIntegrityViolationException otraTransaccionLaCreo) {
            // Otra alta simultánea creó la fila: se usa esa.
        }
        return secuencias.bloquear(prefijo).orElseThrow();
    }
}
