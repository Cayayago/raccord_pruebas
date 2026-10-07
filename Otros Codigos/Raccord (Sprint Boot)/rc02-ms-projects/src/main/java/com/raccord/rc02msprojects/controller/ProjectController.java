package com.raccord.rc02msprojects.controller;

import com.raccord.rc02msprojects.entity.Project;
import com.raccord.rc02msprojects.service.ProjectService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/projects")
@CrossOrigin(origins = "*")
public class ProjectController {

    private final ProjectService projectService;

    public ProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    // ✅ Público
    @GetMapping("/test")
    public String test() { return "✅ RC02 ms-projects - Puerto 8082 funcionando!"; }

    // 🔐 ADMIN - registrar
    @PostMapping
    public ResponseEntity<Project> registrar(@Valid @RequestBody Project project) {
        return ResponseEntity.status(HttpStatus.CREATED).body(projectService.registrar(project));
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Project>> listar() {
        return ResponseEntity.ok(projectService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Project> buscarPorId(@PathVariable String id) {
        return ResponseEntity.ok(projectService.buscarPorId(id));
    }

    // 🔐 USER/ADMIN - buscar por director
    @GetMapping("/director/{director}")
    public ResponseEntity<List<Project>> buscarPorDirector(@PathVariable String director) {
        return ResponseEntity.ok(projectService.buscarPorDirector(director));
    }

    // 🔐 USER/ADMIN - buscar por género
    @GetMapping("/genero/{genero}")
    public ResponseEntity<List<Project>> buscarPorGenero(@PathVariable String genero) {
        return ResponseEntity.ok(projectService.buscarPorGenero(genero));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Project> actualizar(@PathVariable String id, @RequestBody Project project) {
        return ResponseEntity.ok(projectService.actualizar(id, project));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable String id) {
        projectService.eliminar(id);
        return ResponseEntity.ok("Proyecto '" + id + "' eliminado correctamente");
    }
}
