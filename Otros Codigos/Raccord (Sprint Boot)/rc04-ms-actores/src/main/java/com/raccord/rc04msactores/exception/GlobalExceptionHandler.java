package com.raccord.rc04msactores.exception;

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
        ex.getBindingResult().getAllErrors().forEach(e ->
            campos.put(((FieldError) e).getField(), e.getDefaultMessage()));
        Map<String, Object> resp = new HashMap<>();
        resp.put("timestamp", LocalDateTime.now().toString());
        resp.put("status", 400); resp.put("error", "Validación fallida"); resp.put("campos", campos);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(resp);
    }

    @ExceptionHandler(RecursoNoEncontradoException.class)
    public ResponseEntity<Map<String, Object>> manejarNoEncontrado(RecursoNoEncontradoException ex) {
        Map<String, Object> resp = new HashMap<>();
        resp.put("timestamp", LocalDateTime.now().toString());
        resp.put("status", 404); resp.put("error", "No encontrado"); resp.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(resp);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> manejarGenerico(Exception ex) {
        Map<String, Object> resp = new HashMap<>();
        resp.put("timestamp", LocalDateTime.now().toString());
        resp.put("status", 500); resp.put("error", "Error interno"); resp.put("mensaje", ex.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(resp);
    }
}
