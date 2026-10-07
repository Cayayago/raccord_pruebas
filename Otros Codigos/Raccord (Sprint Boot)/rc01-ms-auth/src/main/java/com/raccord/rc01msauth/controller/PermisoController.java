package com.raccord.rc01msauth.controller;

import com.raccord.rc01msauth.entity.Permiso;
import com.raccord.rc01msauth.service.PermisoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/permisos")
@CrossOrigin(origins = "*")
public class PermisoController {

    private final PermisoService permisoService;

    public PermisoController(PermisoService permisoService) {
        this.permisoService = permisoService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Permiso>> listar() {
        return ResponseEntity.ok(permisoService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Permiso> buscarPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(permisoService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Permiso> guardar(@Valid @RequestBody Permiso permiso) {
        return ResponseEntity.status(HttpStatus.CREATED).body(permisoService.guardar(permiso));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Permiso> actualizar(@PathVariable Integer id, @RequestBody Permiso permiso) {
        return ResponseEntity.ok(permisoService.actualizar(id, permiso));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable Integer id) {
        permisoService.eliminar(id);
        return ResponseEntity.ok("Permiso con ID " + id + " eliminado correctamente");
    }
}
