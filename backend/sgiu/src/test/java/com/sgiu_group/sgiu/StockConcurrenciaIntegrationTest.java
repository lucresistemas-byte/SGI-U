package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.exceptions.ConflictoStockException;
import com.sgiu_group.sgiu.models.entities.ArticuloStock;
import com.sgiu_group.sgiu.models.entities.EspProducto;
import com.sgiu_group.sgiu.repositories.ArticuloStockRepository;
import com.sgiu_group.sgiu.repositories.EspProductoRepository;
import com.sgiu_group.sgiu.services.ReintentoStock;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Etapa 5: bloqueo optimista (@Version) en articulos_stock. Sin transacción
 * del test: cada cambio confirma la suya, como en dos pedidos simultáneos.
 */
@SpringBootTest
@ActiveProfiles("test")
class StockConcurrenciaIntegrationTest {

    @Autowired
    private EspProductoRepository productoRepository;
    @Autowired
    private ArticuloStockRepository stockRepository;
    @Autowired
    private ReintentoStock reintento;
    @Autowired
    private PlatformTransactionManager transactionManager;
    @Autowired
    private JdbcTemplate jdbc;

    private TransactionTemplate tx;

    @BeforeEach
    void producto() {
        tx = new TransactionTemplate(transactionManager);
        tx.executeWithoutResult(s -> {
            EspProducto p = productoRepository.save(new EspProducto("CONC-1", "Concurrencia", BigDecimal.TEN));
            stockRepository.save(new ArticuloStock(p, 10));
        });
    }

    @AfterEach
    void limpiar() {
        jdbc.update("DELETE FROM articulos_stock WHERE esp_producto_id IN (SELECT id FROM esp_productos WHERE codigo = 'CONC-1')");
        jdbc.update("DELETE FROM esp_productos WHERE codigo = 'CONC-1'");
    }

    private ArticuloStock leer() {
        return tx.execute(s -> stockRepository.findByEspProducto_Codigo("CONC-1").orElseThrow());
    }

    /** Otro usuario cambia la fila mientras tanto: la copia leída antes queda vieja. */
    private void cambioDeOtroUsuario(int delta) {
        tx.executeWithoutResult(s -> {
            ArticuloStock fila = stockRepository.findByEspProducto_Codigo("CONC-1").orElseThrow();
            fila.setCantidad(fila.getCantidad().add(BigDecimal.valueOf(delta)));
        });
    }

    @Test
    void unaCopiaViejaNoPisaElCambioDeOtro() {
        ArticuloStock vieja = leer();
        cambioDeOtroUsuario(-3);

        vieja.setCantidad(vieja.getCantidad().add(BigDecimal.ONE));
        assertThatThrownBy(() -> tx.executeWithoutResult(s -> stockRepository.save(vieja)))
                .isInstanceOf(ObjectOptimisticLockingFailureException.class);
        assertThat(leer().getCantidad()).isEqualByComparingTo("7");
    }

    @Test
    void conflicto_seReintentaUnaVez_yElReintentoLeeElStockNuevo() {
        ArticuloStock vieja = leer();
        cambioDeOtroUsuario(-3);
        AtomicInteger intentos = new AtomicInteger();

        BigDecimal resultado = reintento.ejecutar(() -> {
            ArticuloStock fila = intentos.incrementAndGet() == 1 ? vieja
                    : stockRepository.findByEspProducto_Codigo("CONC-1").orElseThrow();
            fila.setCantidad(fila.getCantidad().add(BigDecimal.ONE));
            return stockRepository.saveAndFlush(fila).getCantidad();
        });

        assertThat(intentos.get()).isEqualTo(2);
        // 10 − 3 (el otro) + 1 (el reintento): no se perdió ningún cambio.
        assertThat(resultado).isEqualByComparingTo("8");
        assertThat(leer().getCantidad()).isEqualByComparingTo("8");
    }

    @Test
    void siVuelveAChocar_respondeUnErrorClaro() {
        AtomicInteger intentos = new AtomicInteger();

        assertThatThrownBy(() -> reintento.ejecutar(() -> {
            intentos.incrementAndGet();
            ArticuloStock vieja = stockRepository.findByEspProducto_Codigo("CONC-1").orElseThrow();
            // Otro usuario cambia la fila antes de que se guarde esta.
            new TransactionTemplate(transactionManager, propagacionNueva()).executeWithoutResult(s -> {
                ArticuloStock otra = stockRepository.findByEspProducto_Codigo("CONC-1").orElseThrow();
                otra.setCantidad(otra.getCantidad().subtract(BigDecimal.ONE));
            });
            vieja.setCantidad(vieja.getCantidad().add(BigDecimal.ONE));
            return stockRepository.saveAndFlush(vieja);
        }))
                .isInstanceOf(ConflictoStockException.class)
                .hasMessage("Otro usuario cambió el stock de estos artículos al mismo tiempo. "
                        + "No se aplicó nada: intente de nuevo.");
        assertThat(intentos.get()).isEqualTo(2);
        // Solo quedaron los dos cambios del otro usuario.
        assertThat(leer().getCantidad()).isEqualByComparingTo("8");
    }

    private static org.springframework.transaction.support.DefaultTransactionDefinition propagacionNueva() {
        var def = new org.springframework.transaction.support.DefaultTransactionDefinition();
        def.setPropagationBehavior(org.springframework.transaction.TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        return def;
    }
}
