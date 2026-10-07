package com.raccord.rc04msactores.controller;

import com.raccord.rc04msactores.entity.Actor;
import com.raccord.rc04msactores.service.ActorService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/actores")
@CrossOrigin(origins = "*")
public class ActorController {

    private final ActorService actorService;

    public ActorController(ActorService actorService) {
        this.actorService = actorService;
    }

    @GetMapping("/test")
    public String test() { return "✅ RC04 ms-actores - Puerto 8084 funcionando!"; }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Actor>> listar() {
        return ResponseEntity.ok(actorService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Actor> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(actorService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Actor> guardar(@Valid @RequestBody Actor actor) {
        return ResponseEntity.status(HttpStatus.CREATED).body(actorService.guardar(actor));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Actor> actualizar(@PathVariable String id, @RequestBody Actor actor) {
        return ResponseEntity.ok(actorService.actualizar(id, actor));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        actorService.eliminar(id);
        return ResponseEntity.ok("Actor con ID '" + id + "' eliminado correctamente");
    }
}
