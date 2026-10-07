package com.raccord.rc01msauth.controller;

import com.raccord.rc01msauth.dto.LoginRequest;
import com.raccord.rc01msauth.dto.LoginResponse;
import com.raccord.rc01msauth.entity.Usuario;
import com.raccord.rc01msauth.exception.RecursoNoEncontradoException;
import com.raccord.rc01msauth.repository.UsuarioRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final UsuarioRepository usuarioRepository;

    public AuthController(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    // ✅ Público - test
    @GetMapping("/test")
    public String test() {
        return "✅ RC01 ms-auth - Puerto 8081 funcionando!";
    }

    // ✅ Público - login
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        Usuario usuario = usuarioRepository.findByMail(request.getMail())
                .orElseThrow(() -> new RecursoNoEncontradoException(
                        "Usuario '" + request.getMail() + "' no encontrado"));
        if (!usuario.getContrasena().equals(request.getContrasena())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new LoginResponse("Credenciales incorrectas", null));
        }
        return ResponseEntity.ok(new LoginResponse("Login exitoso", "token-" + usuario.getMail()));
    }

    // ✅ Público - registro
    @PostMapping("/registro")
    public ResponseEntity<Usuario> registro(@Valid @RequestBody Usuario usuario) {
        if (usuarioRepository.existsByMail(usuario.getMail())) {
            throw new IllegalArgumentException("Ya existe un usuario con el email: " + usuario.getMail());
        }
        usuario.setFechaCreacion(LocalDateTime.now());
        usuario.setEstado("activo");
        return ResponseEntity.status(HttpStatus.CREATED).body(usuarioRepository.save(usuario));
    }

    // 🔐 USER/ADMIN - listar usuarios
    @GetMapping("/usuarios")
    public ResponseEntity<List<Usuario>> listar() {
        return ResponseEntity.ok(usuarioRepository.findAll());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/usuarios/{id}")
    public ResponseEntity<Usuario> buscarPorId(@PathVariable Long id) {
        Usuario u = usuarioRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario con ID " + id + " no encontrado"));
        return ResponseEntity.ok(u);
    }

    // 🔐 ADMIN - eliminar usuario
    @DeleteMapping("/usuarios/{id}")
    public ResponseEntity<String> eliminar(@PathVariable Long id) {
        if (!usuarioRepository.existsById(id))
            throw new RecursoNoEncontradoException("Usuario con ID " + id + " no encontrado");
        usuarioRepository.deleteById(id);
        return ResponseEntity.ok("Usuario con ID " + id + " eliminado");
    }
}
