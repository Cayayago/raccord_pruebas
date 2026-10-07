package com.raccord.rc01msauth.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> manejarValidaciones(MethodArgumentNotValidException ex) {
        Map<String, String> campos = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String campo = ((FieldError) error).getField();
            campos.put(campo, error.getDefaultMessage());
        });
        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("timestamp", LocalDateTime.now().toString());
        respuesta.put("status", 400);
        respuesta.put("error", "Validación fallida");
        respuesta.put("campos", campos);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(respuesta);
    }

    @ExceptionHandler(RecursoNoEncontradoException.class)
    public ResponseEntity<Map<String, Object>> manejarNoEncontrado(RecursoNoEncontradoException ex) {
        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("timestamp", LocalDateTime.now().toString());
        respuesta.put("status", 404);
        respuesta.put("error", "Recurso no encontrado");
        respuesta.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(respuesta);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> manejarDuplicado(IllegalArgumentException ex) {
        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("timestamp", LocalDateTime.now().toString());
        respuesta.put("status", 400);
        respuesta.put("error", "Dato inválido o duplicado");
        respuesta.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(respuesta);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> manejarGenerico(Exception ex) {
        Map<String, Object> respuesta = new HashMap<>();
        respuesta.put("timestamp", LocalDateTime.now().toString());
        respuesta.put("status", 500);
        respuesta.put("error", "Error interno");
        respuesta.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(respuesta);
    }
}
