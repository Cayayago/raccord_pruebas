package com.raccord.rc03mscontinuidad.controller;

import com.raccord.rc03mscontinuidad.entity.Desglose;
import com.raccord.rc03mscontinuidad.service.DesgloseService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/desgloses")
@CrossOrigin(origins = "*")
public class DesgloseController {

    private final DesgloseService desgloseService;

    public DesgloseController(DesgloseService desgloseService) {
        this.desgloseService = desgloseService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Desglose>> listar() {
        return ResponseEntity.ok(desgloseService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Desglose> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(desgloseService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Desglose> guardar(@Valid @RequestBody Desglose desglose) {
        return ResponseEntity.status(HttpStatus.CREATED).body(desgloseService.guardar(desglose));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Desglose> actualizar(@PathVariable String id, @RequestBody Desglose desglose) {
        return ResponseEntity.ok(desgloseService.actualizar(id, desglose));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        desgloseService.eliminar(id);
        return ResponseEntity.ok("Desglose '" + id + "' eliminado correctamente");
    }
}
