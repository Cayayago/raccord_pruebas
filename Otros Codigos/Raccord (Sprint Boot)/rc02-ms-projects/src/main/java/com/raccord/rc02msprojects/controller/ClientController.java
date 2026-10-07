package com.raccord.rc02msprojects.controller;

import com.raccord.rc02msprojects.entity.Client;
import com.raccord.rc02msprojects.service.ClientService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/clients")
@CrossOrigin(origins = "*")
public class ClientController {

    private final ClientService clientService;

    public ClientController(ClientService clientService) {
        this.clientService = clientService;
    }

    // 🔐 ADMIN - registrar
    @PostMapping
    public ResponseEntity<Client> registrar(@Valid @RequestBody Client client) {
        return ResponseEntity.status(HttpStatus.CREATED).body(clientService.registrar(client));
    }

    // 🔐 USER/ADMIN - listar
    @GetMapping
    public ResponseEntity<List<Client>> listar() {
        return ResponseEntity.ok(clientService.listar());
    }

    // 🔐 USER/ADMIN - buscar por ID
    @GetMapping("/{id}")
    public ResponseEntity<Client> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(clientService.buscarPorId(id));
    }

    // 🔐 USER/ADMIN - buscar por email
    @GetMapping("/email/{email}")
    public ResponseEntity<Client> buscarPorEmail(@PathVariable String email) {
        return ResponseEntity.ok(clientService.buscarPorEmail(email));
    }

    // 🔐 ADMIN - actualizar parcialmente
    @PatchMapping("/{id}")
    public ResponseEntity<Client> actualizar(@PathVariable Long id, @RequestBody Client client) {
        return ResponseEntity.ok(clientService.actualizar(id, client));
    }

    // 🔐 ADMIN - eliminar
    @DeleteMapping("/{id}")
    public ResponseEntity<String> eliminar(@PathVariable Long id) {
        clientService.eliminar(id);
        return ResponseEntity.ok("Cliente con ID " + id + " eliminado correctamente");
    }
}
