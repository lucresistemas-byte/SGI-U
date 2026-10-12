package com.sgiu_group.sgiu;

import com.sgiu_group.sgiu.models.entities.TipoArticulo;
import com.sgiu_group.sgiu.repositories.SecuenciaCodigoRepository;
import com.sgiu_group.sgiu.services.CodigoService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Corrección 9: altas simultáneas nunca reciben el mismo código. Sin
 * @Transactional de test: cada hilo confirma su propia transacción.
 */
@SpringBootTest
@ActiveProfiles("test")
class CodigoServiceConcurrenciaTest {

    @Autowired
    private CodigoService codigoService;
    @Autowired
    private TransactionTemplate transactionTemplate;
    @Autowired
    private SecuenciaCodigoRepository secuencias;

    @AfterEach
    void limpiar() {
        secuencias.deleteById(TipoArticulo.PAQUETE.getPrefijo());
    }

    @Test
    void altasSimultaneas_recibenCodigosDistintosYCorrelativos() throws Exception {
        int altas = 8;
        ExecutorService hilos = Executors.newFixedThreadPool(altas);
        try {
            List<Callable<String>> tareas = new ArrayList<>();
            for (int i = 0; i < altas; i++) {
                tareas.add(() -> transactionTemplate.execute(
                        estado -> codigoService.siguiente(TipoArticulo.PAQUETE)));
            }
            List<String> codigos = new ArrayList<>();
            for (Future<String> f : hilos.invokeAll(tareas)) {
                codigos.add(f.get());
            }

            assertThat(codigos).doesNotHaveDuplicates()
                    .containsExactlyInAnyOrder("PAQ-0001", "PAQ-0002", "PAQ-0003", "PAQ-0004",
                            "PAQ-0005", "PAQ-0006", "PAQ-0007", "PAQ-0008");
        } finally {
            hilos.shutdownNow();
        }
    }
}
