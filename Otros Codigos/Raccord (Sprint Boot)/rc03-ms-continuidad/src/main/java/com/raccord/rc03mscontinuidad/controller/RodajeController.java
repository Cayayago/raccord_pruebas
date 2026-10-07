package com.raccord.rc03mscontinuidad.controller;

import com.raccord.rc03mscontinuidad.entity.Rodaje;
import com.raccord.rc03mscontinuidad.service.RodajeService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/rodajes")
@CrossOrigin(origins = "*")
public class RodajeController {

    private final RodajeService rodajeService;

    public RodajeController(RodajeService rodajeService) {
        this.rodajeService = rodajeService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Rodaje>> listar() {
        return ResponseEntity.ok(rodajeService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Rodaje> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(rodajeService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Rodaje> guardar(@Valid @RequestBody Rodaje rodaje) {
        return ResponseEntity.status(HttpStatus.CREATED).body(rodajeService.guardar(rodaje));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Rodaje> actualizar(@PathVariable String id, @RequestBody Rodaje rodaje) {
        return ResponseEntity.ok(rodajeService.actualizar(id, rodaje));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        rodajeService.eliminar(id);
        return ResponseEntity.ok("Rodaje '" + id + "' eliminado correctamente");
    }
}
