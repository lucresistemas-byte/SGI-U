package com.sgiu_group.sgiu.exceptions;

import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.time.LocalDate;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @SuppressWarnings("unchecked")
    private Map<String, Object> cuerpo(ResponseEntity<?> respuesta) {
        return (Map<String, Object>) respuesta.getBody();
    }

    private MethodArgumentNotValidException excepcionDeValidacion(String campo, String mensaje)
            throws NoSuchMethodException {
        MethodParameter param = MethodParameter.forExecutable(
                GlobalExceptionHandlerTest.class.getDeclaredMethod("metodoValidado", String.class, Integer.class), 0);
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "request");
        bindingResult.addError(new FieldError(
                "request", campo, null, false, null, null, mensaje));
        return new MethodArgumentNotValidException(param, bindingResult);
    }

    @SuppressWarnings("unused")
    private static void metodoValidado(String campo, Integer valor) {
    }

    @Test
    void handleValidation_devuelve400ConElPrimerMensajeDeError() throws Exception {
        MethodArgumentNotValidException ex = excepcionDeValidacion(
                "precioUnitario", "El precio debe ser un valor mayor a $0.");

        ResponseEntity<?> respuesta = handler.handleValidation(ex);

        assertThat(respuesta.getStatusCode().value()).isEqualTo(400);
        assertThat(cuerpo(respuesta)).containsEntry("error", "El precio debe ser un valor mayor a $0.");
    }

    @Test
    void handleDataIntegrity_devuelve409ConMensajeDeCodigoDuplicado() {
        ResponseEntity<?> respuesta = handler.handleDataIntegrity(new DataIntegrityViolationException("uk"));

        assertThat(respuesta.getStatusCode().value()).isEqualTo(409);
        assertThat(cuerpo(respuesta)).containsEntry("error", "El código de producto ya existe.");
    }

    @Test
    void handleTypeMismatch_devuelve400ConFormatoDeFecha() throws Exception {
        MethodParameter param = MethodParameter.forExecutable(
                GlobalExceptionHandlerTest.class.getDeclaredMethod("parametroFecha", LocalDate.class), 0);
        MethodArgumentTypeMismatchException ex = new MethodArgumentTypeMismatchException(
                "2026-13-40", LocalDate.class, "fechaInicio", param, null);

        ResponseEntity<?> respuesta = handler.handleTypeMismatch(ex);

        assertThat(respuesta.getStatusCode().value()).isEqualTo(400);
        assertThat(cuerpo(respuesta)).containsEntry(
                "error", "Formato de fecha inválido. Use el formato ISO: yyyy-MM-dd.");
    }

    @SuppressWarnings("unused")
    private static void parametroFecha(LocalDate fecha) {
    }

    @Test
    void handleFechasInvalidas_devuelve400ConCodigoFECHAS_INVALIDAS () {
        ResponseEntity<?> respuesta = handler.handleFechasInvalidas(new FechasInvalidasException("mal"));

        assertThat(respuesta.getStatusCode().value()).isEqualTo(400);
        assertThat(cuerpo(respuesta)).containsEntry("codigo", "FECHAS_INVALIDAS");
        assertThat(cuerpo(respuesta)).containsEntry("mensaje", "mal");
    }

    @Test
    void handleFiltroInvalido_devuelve400ConCodigoFILTRO_INVALIDO () {
        ResponseEntity<?> respuesta = handler.handleFiltroInvalido(new FiltroInvalidoException("mal"));

        assertThat(respuesta.getStatusCode().value()).isEqualTo(400);
        assertThat(cuerpo(respuesta)).containsEntry("codigo", "FILTRO_INVALIDO");
    }

    @Test
    void handleAccessDenied_devuelve401ConCodigoTOKEN_INVALIDO () {
        ResponseEntity<?> respuesta = handler.handleAccessDenied(
                new org.springframework.security.access.AccessDeniedException("denegado"));

        assertThat(respuesta.getStatusCode().value()).isEqualTo(401);
        assertThat(cuerpo(respuesta)).containsEntry("codigo", "TOKEN_INVALIDO");
        assertThat(cuerpo(respuesta)).containsEntry("mensaje", "Token inválido o expirado");
    }

    @Test
    void handleGeneral_devuelve500ConCodigoERROR_DASHBOARD () {
        ResponseEntity<?> respuesta = handler.handleGeneral(new RuntimeException("boom"));

        assertThat(respuesta.getStatusCode().value()).isEqualTo(500);
        assertThat(cuerpo(respuesta)).containsEntry("codigo", "ERROR_DASHBOARD");
        assertThat(cuerpo(respuesta)).containsEntry("mensaje", "No se pudo generar el Dashboard");
    }
}