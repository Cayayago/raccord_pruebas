package com.raccord.rc01msauth.controller;

import com.raccord.rc01msauth.entity.Rol;
import com.raccord.rc01msauth.service.RolService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/roles")
@CrossOrigin(origins = "*")
public class RolController {

    private final RolService rolService;

    public RolController(RolService rolService) {
        this.rolService = rolService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Rol>> listar() {
        return ResponseEntity.ok(rolService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Rol> buscarPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(rolService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Rol> guardar(@Valid @RequestBody Rol rol) {
        return ResponseEntity.status(HttpStatus.CREATED).body(rolService.guardar(rol));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Rol> actualizar(@PathVariable Integer id, @RequestBody Rol rol) {
        return ResponseEntity.ok(rolService.actualizar(id, rol));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable Integer id) {
        rolService.eliminar(id);
        return ResponseEntity.ok("Rol con ID " + id + " eliminado correctamente");
    }
}
