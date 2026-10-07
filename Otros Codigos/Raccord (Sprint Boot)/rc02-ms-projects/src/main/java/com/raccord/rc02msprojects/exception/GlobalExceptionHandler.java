package com.raccord.rc02msprojects.exception;

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
        ex.getBindingResult().getAllErrors().forEach(e -> {
            campos.put(((FieldError) e).getField(), e.getDefaultMessage());
        });
        Map<String, Object> r = new HashMap<>();
        r.put("timestamp", LocalDateTime.now().toString());
        r.put("status", 400);
        r.put("error", "Validación fallida");
        r.put("campos", campos);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(r);
    }

    @ExceptionHandler(RecursoNoEncontradoException.class)
    public ResponseEntity<Map<String, Object>> manejarNoEncontrado(RecursoNoEncontradoException ex) {
        Map<String, Object> r = new HashMap<>();
        r.put("timestamp", LocalDateTime.now().toString());
        r.put("status", 404);
        r.put("error", "Recurso no encontrado");
        r.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(r);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> manejarDuplicado(IllegalArgumentException ex) {
        Map<String, Object> r = new HashMap<>();
        r.put("timestamp", LocalDateTime.now().toString());
        r.put("status", 400);
        r.put("error", "Dato inválido o duplicado");
        r.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(r);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> manejarGenerico(Exception ex) {
        Map<String, Object> r = new HashMap<>();
        r.put("timestamp", LocalDateTime.now().toString());
        r.put("status", 500);
        r.put("error", "Error interno");
        r.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(r);
    }
}
