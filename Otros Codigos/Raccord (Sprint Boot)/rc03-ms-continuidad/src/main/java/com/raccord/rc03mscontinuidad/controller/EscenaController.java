package com.raccord.rc03mscontinuidad.controller;

import com.raccord.rc03mscontinuidad.entity.Escena;
import com.raccord.rc03mscontinuidad.service.EscenaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/escenas")
@CrossOrigin(origins = "*")
public class EscenaController {

    private final EscenaService escenaService;

    public EscenaController(EscenaService escenaService) {
        this.escenaService = escenaService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Escena>> listar() {
        return ResponseEntity.ok(escenaService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Escena> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(escenaService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Escena> guardar(@Valid @RequestBody Escena escena) {
        return ResponseEntity.status(HttpStatus.CREATED).body(escenaService.guardar(escena));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Escena> actualizar(@PathVariable String id, @RequestBody Escena escena) {
        return ResponseEntity.ok(escenaService.actualizar(id, escena));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        escenaService.eliminar(id);
        return ResponseEntity.ok("Escena '" + id + "' eliminada correctamente");
    }
}
