package com.raccord.rc03mscontinuidad.controller;

import com.raccord.rc03mscontinuidad.entity.Guion;
import com.raccord.rc03mscontinuidad.service.GuionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/guiones")
@CrossOrigin(origins = "*")
public class GuionController {

    private final GuionService guionService;

    public GuionController(GuionService guionService) {
        this.guionService = guionService;
    }

    @GetMapping("/test")
    public String test() { return "✅ RC03 ms-continuidad - Puerto 8083 funcionando!"; }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Guion>> listar() {
        return ResponseEntity.ok(guionService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Guion> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(guionService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Guion> guardar(@Valid @RequestBody Guion guion) {
        return ResponseEntity.status(HttpStatus.CREATED).body(guionService.guardar(guion));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Guion> actualizar(@PathVariable Long id, @RequestBody Guion guion) {
        return ResponseEntity.ok(guionService.actualizar(id, guion));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable Long id) {
        guionService.eliminar(id);
        return ResponseEntity.ok("Guion con ID " + id + " eliminado correctamente");
    }
}
