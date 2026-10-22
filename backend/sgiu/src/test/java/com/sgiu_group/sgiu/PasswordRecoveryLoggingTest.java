package com.sgiu_group.sgiu;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.sgiu_group.sgiu.controllers.auth.AuthController;
import com.sgiu_group.sgiu.security.RecoveryKeyService;
import com.sgiu_group.sgiu.support.TestDataFactory;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * SEG-07: los logs no deben contener la clave de recuperación ni las
 * contraseñas.
 */
class PasswordRecoveryLoggingTest extends AbstractIntegrationTest {

    @Autowired
    private TestDataFactory datos;

    @Value("${sgiu.recovery.key}")
    private String claveRecuperacion;

    private final ListAppender<ILoggingEvent> apuntador = new ListAppender<>();
    private Logger loggerController;

    @BeforeEach
    void preparar() {
        loggerController = (Logger) LoggerFactory.getLogger(AuthController.class);
        apuntador.start();
        loggerController.addAppender(apuntador);
    }

    @AfterEach
    void limpiar() {
        loggerController.detachAppender(apuntador);
        apuntador.stop();
        apuntador.list.clear();
    }

    @Test
    @DisplayName("SEG-07: los logs del controller no contienen la clave ni la contraseña nueva")
    void logsDelControllerSinSecretos() throws Exception {
        datos.crearUsuario("rec_seg07", "vieja123", true);

        mockMvc.perform(post("/api/auth/recuperar-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\": \"rec_seg07\", \"claveRecuperacion\": \"" + claveRecuperacion
                                + "\", \"passwordNueva\": \"NuevaClaveSecreta123\"}"))
                .andExpect(status().isOk());

        assertThat(apuntador.list)
                .extracting(ILoggingEvent::getFormattedMessage)
                .doesNotContain(claveRecuperacion, "NuevaClaveSecreta123");
    }

    @Test
    @DisplayName("SEG-07: RecoveryKeyService nunca loguea el contenido de la clave")
    void logsDelServicioSinClave() {
        Logger loggerServicio = (Logger) LoggerFactory.getLogger(RecoveryKeyService.class);
        ListAppender<ILoggingEvent> apuntadorServicio = new ListAppender<>();
        apuntadorServicio.start();
        loggerServicio.addAppender(apuntadorServicio);
        try {
            RecoveryKeyService servicio = new RecoveryKeyService();
            ReflectionTestUtils.setField(servicio, "configuredKey", claveRecuperacion);
            servicio.init();
            servicio.coincide(claveRecuperacion);

            assertThat(apuntadorServicio.list)
                    .extracting(ILoggingEvent::getFormattedMessage)
                    .doesNotContain(claveRecuperacion);
        } finally {
            loggerServicio.detachAppender(apuntadorServicio);
            apuntadorServicio.stop();
        }
    }
}
