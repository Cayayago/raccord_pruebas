package com.raccord.rc01msauth.controller;

import com.raccord.rc01msauth.entity.Usuario;
import com.raccord.rc01msauth.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
@CrossOrigin(origins = "*")
public class UsuarioController {

    private final UsuarioService usuarioService;

    public UsuarioController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Usuario>> listar() {
        return ResponseEntity.ok(usuarioService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Usuario> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(usuarioService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Usuario> guardar(@Valid @RequestBody Usuario usuario) {
        return ResponseEntity.status(HttpStatus.CREATED).body(usuarioService.guardar(usuario));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Usuario> actualizar(@PathVariable Long id, @RequestBody Usuario usuario) {
        return ResponseEntity.ok(usuarioService.actualizar(id, usuario));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable Long id) {
        usuarioService.eliminar(id);
        return ResponseEntity.ok("Usuario con ID " + id + " eliminado correctamente");
    }
}
