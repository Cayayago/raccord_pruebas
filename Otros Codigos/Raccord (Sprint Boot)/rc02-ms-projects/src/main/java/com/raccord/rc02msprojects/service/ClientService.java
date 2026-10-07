package com.raccord.rc02msprojects.service;

import com.raccord.rc02msprojects.entity.Client;
import com.raccord.rc02msprojects.exception.RecursoNoEncontradoException;
import com.raccord.rc02msprojects.repository.ClientRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ClientService {

    private final ClientRepository clientRepository;

    public ClientService(ClientRepository clientRepository) {
        this.clientRepository = clientRepository;
    }

    public Client registrar(Client client) {
        if (client.getRazonSocial() == null || client.getRazonSocial().trim().isEmpty())
            throw new IllegalArgumentException("La razón social no puede estar vacía");
        if (clientRepository.existsByEmail(client.getEmail()))
            throw new IllegalArgumentException("Ya existe un cliente con email: " + client.getEmail());
        if (clientRepository.existsByDocument(client.getIdDocument()))
            throw new IllegalArgumentException("Ya existe un cliente con documento: " + client.getIdDocument());
        return clientRepository.save(client);
    }

    public List<Client> listar() { return clientRepository.findAll(); }

    public Client buscarPorId(Long id) {
        return clientRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cliente con ID " + id + " no encontrado"));
    }

    public Client buscarPorEmail(String email) {
        return clientRepository.findByEmail(email)
                .orElseThrow(() -> new RecursoNoEncontradoException("Cliente con email '" + email + "' no encontrado"));
    }

    public Client actualizar(Long id, Client datos) {
        Client existente = buscarPorId(id);
        if (datos.getRazonSocial() != null) existente.setRazonSocial(datos.getRazonSocial());
        if (datos.getRepresentanteLegal() != null) existente.setRepresentanteLegal(datos.getRepresentanteLegal());
        if (datos.getAddress() != null) existente.setAddress(datos.getAddress());
        if (datos.getTelephone() != null) existente.setTelephone(datos.getTelephone());
        if (datos.getNumberCellphone() != null) existente.setNumberCellphone(datos.getNumberCellphone());
        return clientRepository.save(existente);
    }

    public void eliminar(Long id) {
        if (!clientRepository.existsById(id))
            throw new RecursoNoEncontradoException("Cliente con ID " + id + " no existe");
        clientRepository.deleteById(id);
    }
}
