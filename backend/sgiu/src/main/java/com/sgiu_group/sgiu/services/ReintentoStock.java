package com.sgiu_group.sgiu.services;

import com.sgiu_group.sgiu.exceptions.ConflictoStockException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.function.Supplier;

/**
 * Cambios de stock con bloqueo optimista (@Version en articulos_stock): si
 * otro cambio simultáneo tocó la misma fila, se reintenta una vez en una
 * transacción nueva; si vuelve a chocar, se responde un error claro.
 */
@Slf4j
@Component
public class ReintentoStock {

    static final String MENSAJE = "Otro usuario cambió el stock de estos artículos al mismo tiempo. "
            + "No se aplicó nada: intente de nuevo.";

    private final TransactionTemplate transaccion;

    public ReintentoStock(PlatformTransactionManager transactionManager) {
        this.transaccion = new TransactionTemplate(transactionManager);
    }

    public <T> T ejecutar(Supplier<T> cambio) {
        try {
            return transaccion.execute(estado -> cambio.get());
        } catch (OptimisticLockingFailureException primero) {
            log.warn("[STOCK] Conflicto de concurrencia, se reintenta una vez: {}", primero.getMessage());
            try {
                return transaccion.execute(estado -> cambio.get());
            } catch (OptimisticLockingFailureException segundo) {
                throw new ConflictoStockException(MENSAJE);
            }
        }
    }
}
