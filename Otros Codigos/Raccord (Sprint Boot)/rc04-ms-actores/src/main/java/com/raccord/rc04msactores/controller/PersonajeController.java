package com.raccord.rc04msactores.controller;

import com.raccord.rc04msactores.entity.Personaje;
import com.raccord.rc04msactores.service.PersonajeService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/personajes")
@CrossOrigin(origins = "*")
public class PersonajeController {

    private final PersonajeService personajeService;

    public PersonajeController(PersonajeService personajeService) {
        this.personajeService = personajeService;
    }

    @GetMapping("/test")
    public String test() { return "✅ RC04 ms-actores/personajes - funcionando!"; }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Personaje>> listar() {
        return ResponseEntity.ok(personajeService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Personaje> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(personajeService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Personaje> guardar(@Valid @RequestBody Personaje personaje) {
        return ResponseEntity.status(HttpStatus.CREATED).body(personajeService.guardar(personaje));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Personaje> actualizar(@PathVariable String id, @RequestBody Personaje personaje) {
        return ResponseEntity.ok(personajeService.actualizar(id, personaje));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        personajeService.eliminar(id);
        return ResponseEntity.ok("Personaje con ID '" + id + "' eliminado correctamente");
    }
}
