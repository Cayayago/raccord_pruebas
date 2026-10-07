package com.raccord.rc01msauth.controller;

import com.raccord.rc01msauth.entity.Departamento;
import com.raccord.rc01msauth.service.DepartamentoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/departamentos")
@CrossOrigin(origins = "*")
public class DepartamentoController {

    private final DepartamentoService departamentoService;

    public DepartamentoController(DepartamentoService departamentoService) {
        this.departamentoService = departamentoService;
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Departamento>> listar() {
        return ResponseEntity.ok(departamentoService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Departamento> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(departamentoService.buscarPorId(id));
    }

    // 🔐 ADMIN - crear
    @PostMapping
    public ResponseEntity<Departamento> guardar(@Valid @RequestBody Departamento departamento) {
        return ResponseEntity.status(HttpStatus.CREATED).body(departamentoService.guardar(departamento));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Departamento> actualizar(@PathVariable String id, @RequestBody Departamento departamento) {
        return ResponseEntity.ok(departamentoService.actualizar(id, departamento));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        departamentoService.eliminar(id);
        return ResponseEntity.ok("Departamento '" + id + "' eliminado correctamente");
    }
}
